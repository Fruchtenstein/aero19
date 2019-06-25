#!/usr/bin/ruby -W0
require 'csv'
require 'sqlite3'
require 'httpclient'
require 'json'
require 'active_support'
require 'active_support/core_ext'
require_relative './config.rb'

def auth (reftoken)
    c = HTTPClient.new
    loginurl = "https://www.strava.com/oauth/token"
    data = { "client_id" => CLIENT_ID, "client_secret" => CLIENT_SECRET, "grant_type" => "refresh_token", "refresh_token" => reftoken}
    resp = c.post(loginurl, data)
    j = JSON.parse(resp.content)
    return j['access_token']
end

$stdout.sync = true
now = Time.now.getutc
if now < STARTPROLOG or now > CLOSECUP
    puts "#{now}: Not yet time..."
    exit
end
if now.wday.between?(1,DOW-1)
    getstart = 1.week.ago.getutc.beginning_of_week
else
    getstart = now.beginning_of_week
end
if getstart < STARTPROLOG
    getstart = STARTPROLOG
end
getend = now.end_of_week
if getend > CLOSECUP
    getend = CLOSECUP
end
p getstart
p getend
p now

conn = HTTPClient.new
db = SQLite3::Database.new("2019.db")
url = "https://www.strava.com/api/v3/athlete/activities"
p url
db.execute("DELETE FROM log WHERE date>'#{getstart.iso8601}' and date<'#{getend.iso8601}'")

db.execute("SELECT runnerid, sid, reftoken, runnername, teamid, goal FROM runners WHERE reftoken IS NOT NULL") do |r|
    rid, sid, reftoken, rname, tid, goal = r 
    puts "#{rid}, #{sid}: #{rname}"
    token = auth(reftoken)
    after = getstart.to_i
    before = getend.to_i
    d = {"after" => after, "before" => before, "per_page" => 100}
    h = {"Authorization" => "Bearer #{token}"}
    #   resp = c.post(url, {"after" => after, "before" => before, "per_page" => 300}, {"Authorization" => "Bearer #{token}"})
    resp = conn.get(url, d, h)
    if resp.status == 200 then
        j = JSON.parse(resp.content)
        p j
        j.each do |run|
            id, type, distance, start_date, time = run['id'], run['type'], run['distance'], run['start_date'], run['moving_time']
            if type == 'Run'
                p "INSERT OR REPLACE INTO log VALUES(#{id}, #{rid}, '#{start_date}', #{distance/1000}, #{time.to_i}, '#{type}')"
                db.execute("INSERT OR REPLACE INTO log VALUES(#{id}, #{rid}, '#{start_date}', #{distance/1000}, #{time.to_i}, '#{type}')")
            end
        end
    else
        print "ERROR: response code #{resp.status}, content: #{resp.content}"
    end
end
