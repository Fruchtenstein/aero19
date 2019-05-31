#!/usr/bin/ruby -W0
require 'csv'
require 'sqlite3'
require 'httpclient'
require 'nokogiri'
require 'active_support'
require 'active_support/core_ext'
require_relative './config.rb'

def auth ()
    creds = File.readlines('credentials', chomp:true)
    creds[0]=creds[0].chomp
    creds[1]=creds[1].chomp
    c = HTTPClient.new
    loginurl = "http://aerobia.ru/api/sign_in"
    data = { "user[email]" => creds[0], "user[password]" => creds[1] }
    resp = c.post(loginurl, data)
    x = Nokogiri::XML(resp.content)
    return x.at_xpath('//authentication_token')["value"]
end

$stdout.sync = true
now = Time.now.getutc
if now < STARTPROLOG or now > CLOSECUP
    puts "#{now}: Not yet time..."
    exit
end
getstart = Time.now.beginning_of_year
if getstart < STARTPROLOG
    getstart = STARTPROLOG
end
getend = now.end_of_week
if getend > CLOSECUP
    getend = CLOSECUP
end
conn = HTTPClient.new
token = auth
puts "-------- First token: #{token}"
db = SQLite3::Database.new("2019.db")
#db.execute("DELETE FROM log WHERE date>'#{getstart.iso8601}' and date<'#{getend.iso8601}' AND runnerid=")
runners = []
db.execute("SELECT * FROM runners WHERE runnerid=") do |r|
    rid, rname, tid, goal = r
    (1..now.month).each do |m|
        url = "http://aerobia.ru/api/users/#{rid}/calendar/2019/#{m.to_s.rjust(2,'0')}"
        begin
            retries ||= 0
            resp = conn.get(url, { "authentication_token" => token })
            puts "....... #{url}"
            puts "....... HTTP status code: #{resp.status}"
            if resp.status != 200
                puts "!!!!!!! HTTP status code: #{resp.status}"
                raise 'Not200'
            end
            x = Nokogiri::XML(resp.content)
            status = x.xpath("//info")[0]
            if status["status_code"] == "401"
                puts "!!!!!!! token error"
                raise 'token_error'
            end
        rescue => e
            puts 'retry:', $!, $@
            sleep 1
            if e == 'token_error'
                token = auth
                puts "-------- New token: #{token}"
            end
            retry if (retries += 1) < 3
            next
        end
#        File.open('calendar.xml', 'a') {|f| f.write(resp.content) }
        runs = x.xpath("//r")
        runs.each do |r|
            p r
            if (r['start_at'] >= getstart) and (r['start_at'] <= getend)
                if ['Бег', 'Спортивное ориентирование', 'Беговая дорожка'].include? r["sport"]
                    sql = "INSERT OR REPLACE INTO log VALUES(#{r['id']}, #{rid}, '#{r['start_at']}', #{r['distance']}, #{r['duration'].to_i}, '#{r['sport']}')"
                    p sql
                    db.execute(sql)
                end
            end
        end
    end
#    dist = db.execute("SELECT COALESCE(SUM(distance),0) FROM log WHERE runnerid=#{rid} AND date>#{1.week.ago.beginning_of_week} and date<#{1.week.ago.end_of_week}")[0]
#    db.execute("INSERT OR REPLACE INTO wlog VALUES (
end
