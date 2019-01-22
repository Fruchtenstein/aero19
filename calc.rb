#!/usr/bin/ruby -W0
require 'sqlite3'
require 'active_support'
require 'active_support/core_ext'
require_relative './config.rb'

def calcweek (now)
    week_number = now.to_date.cweek.to_i
    db = SQLite3::Database.new("2019.db")
    teams = []
    (1..TEAMS).each do |t|
        num_of_runners = db.execute("SELECT COUNT(*) FROM runners WHERE teamid=#{t}")[0][0]
        sum_pct = 0
        db.execute("SELECT runnerid, goal*7/365.0 FROM runners WHERE teamid=#{t}") do |r|
            dist = db.execute("SELECT COALESCE(SUM(distance),0) FROM log WHERE runnerid=#{r[0]} AND date>'#{now.beginning_of_week.iso8601}' AND date<'#{now.end_of_week.iso8601}'")[0][0]
            goal = r[1]
            sum_pct += (dist/goal)*100
        end
        teams << [t, week_number, sum_pct/num_of_runners]
    end
    teams.sort! { |x,y| y[2] <=> x[2] }
    teams.each do |t|
        place = teams.index(t)+1
        points = 5*(TEAMS-place)
        p          "INSERT OR REPLACE INTO points VALUES (#{t[0]}, #{week_number}, #{points}, #{t[2]})"
        db.execute("INSERT OR REPLACE INTO points VALUES (#{t[0]}, #{week_number}, #{points}, #{t[2]})")
    end
end

def calcprolog ()
    db = SQLite3::Database.new("2019.db")
    teams = Array.new(TEAMS, 0)
    runners = db.execute("SELECT * FROM runners") 
    runners.each do |r|
        r << db.execute("SELECT COALESCE(SUM(distance),0) AS d FROM log WHERE runnerid=#{r[0]} AND date>'#{STARTPROLOG.iso8601}' AND date<'#{ENDPROLOG.iso8601}' LIMIT 3")[0][0]
    end
    p runners
    runners.sort! { |x,y| y[4] <=> x[4] }
    p runners
    teams[runners[0][2]] += 20
    teams[runners[1][2]] += 10
    teams[runners[2][2]] += 5
    teams.each_with_index do |t, i|
        db.execute("INSERT OR REPLACE INTO points VALUES (#{i}, 1, #{t}, 0.0)")
    end
end

now = Time.now.getutc

if now.wday == DOW and now.to_date.cweek == 2
    calcprolog
end

if now.wday.between?(1, DOW-1) and 1.week.ago.getutc.beginning_of_week >= STARTCHM and 1.week.ago.getutc.beginning_of_week <= ENDCHM
    p "do last week #{1.week.ago}"
    calcweek(1.week.ago)
end


if now.beginning_of_week >= STARTCHM and now.beginning_of_week <= ENDCHM
    p "do this week #{now}"
    calcweek(now)
end

