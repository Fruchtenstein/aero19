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
db.execute("SELECT sid, reftoken, runnername, teamid, goal FROM runners WHERE reftoken IS NOT NULL AND sid=19280944") do |r|
   sid, reftoken, rname, tid, goal = r 
   token = auth(reftoken)
   after = getstart.to_i
   before = getend.to_i
   d = {"after" => after, "before" => before, "per_page" => 100}
   h = {"Authorization" => "Bearer #{token}"}
#   resp = c.post(url, {"after" => after, "before" => before, "per_page" => 300}, {"Authorization" => "Bearer #{token}"})
   resp = conn.get(url, d, h)
   j = JSON.parse(resp.content)
   j.each do |run|
      p run['type'], run['distance'], run['start_date'], 16.666666667/run['average_speed'].to_f
   end
end
