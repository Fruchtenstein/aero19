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
if now < STARTPROLOG or now > ENDCUP
    puts "#{now}: Not yet time..."
    exit
end
if now.wday.between?(1,DOW-1)
    getstart = 1.week.ago.beginning_of_week
else
    getstart = now.beginning_of_week
end
if getstart < STARTPROLOG
    getstart = STARTPROLOG
end
getend = now.end_of_week
if getend > ENDCUP
    getend = ENDCUP
end
conn = HTTPClient.new
token = auth
puts "-------- First token: #{token}"
db = SQLite3::Database.new("2019.db")
db.execute("DELETE FROM log WHERE date>'#{getstart.iso8601}' and date<'#{getend.iso8601}'")
runners = []
db.execute("SELECT * FROM runners") do |r|
    rid, rname, tid, goal = r
    [1.month.ago, now].each do |m|
        url = "http://aerobia.ru/api/users/#{rid}/calendar/#{m.year}/#{m.month.to_s.rjust(2,'0')}"
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
        end
#        File.open('calendar.xml', 'a') {|f| f.write(resp.content) }
        runs = x.xpath("//r")
        runs.each do |r|
            if (r['start_at'] >= getstart) and (r['start_at'] <= getend)
                if ['Бег', 'Спортивное ориентирование', 'Беговая дорожка'].include? r["sport"]
                    sql = "INSERT OR REPLACE INTO log VALUES(#{r['id']}, #{rid}, '#{r['start_at']}', #{r['distance']}, #{r['duration']}, '#{r['sport']}')"
                    p sql
                    db.execute(sql)
                end
            end
        end
    end
#    dist = db.execute("SELECT COALESCE(SUM(distance),0) FROM log WHERE runnerid=#{rid} AND date>#{1.week.ago.beginning_of_week} and date<#{1.week.ago.end_of_week}")[0]
#    db.execute("INSERT OR REPLACE INTO wlog VALUES (
end

if now.wday == DOW and 1.week.ago.beginning_of_week >= STARTCHM and 1.week.ago.beginning_of_week <= ENDCHM
    teams = []
    (1..TEAMS).each do |t|
        num_of_runners = db.execute("SELECT COUNT(*) FROM runners WHERE teamid=#{t}")[0][0]
        sum_pct = 0
        db.execute("SELECT runnerid, goal*7/365.0 FROM runners WHERE teamid=#{t}") do |r|
            dist = db.execute("SELECT COALESCE(SUM(distance),0) FROM log WHERE runnerid=#{r[0]} AND date>'#{1.week.ago.beginning_of_week}' AND date<'#{1.week.ago.end_of_week}'")[0][0]
            goal = r[1]
            sum_pct += (dist/goal)*100
        end
        teams << [t, 1.week.ago.strftime("%W").to_i, sum_pct/num_of_runners]
    end
    teams.sort! { |x,y| y[2] <=> x[2] }
    p teams
end


if now.wday == DOW and 1.week.ago.beginning_of_week >= STARTCHM and 1.week.ago.beginning_of_week <= ENDCHM

end
