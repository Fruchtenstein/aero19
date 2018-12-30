#!/usr/bin/ruby -W0
require 'sqlite3'
require 'active_support'
require 'active_support/core_ext'
require 'erb'
require_relative './config.rb'

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

today = DateTime.parse(now.to_s)
week = today.cweek
prolog = ""

index_erb = ERB.new(File.read('index.html.erb'))
rules_erb = ERB.new(File.read('rules.html.erb'))
user_erb = ERB.new(File.read('u.html.erb'))

db = SQLite3::Database.new("2019.db")

prolog += "<center>\n"
prolog += "<h1>Пролог</h1>\n"
prolog += "</center>\n"
prolog += "<div class=\"datagrid\">\n"
prolog += "<table>\n"
prolog += "<thead><tr><th>Имя</th><th>Команда</th><th>Цель2018 (км)</th><th>Результат (км)</th></tr></thead>\n"
prolog += "<tbody>\n"

teams = db.execute("SELECT * FROM teams")

odd = true
runners = db.execute("SELECT runnerid,runnername,7*goal/365,teamid FROM runners")
runners.each do |r|
    r << db.execute("SELECT COALESCE(SUM(distance),0) AS dist FROM log WHERE runnerid=#{r[0]} AND date>'#{STARTPROLOG.iso8601}' AND date<'#{ENDPROLOG.iso8601}'")[0][0]
end
runners.sort! { |x,y| y[4] <=> x[4] }
runners.each do |r|
    if odd then
        prolog += "<tr><td><a href=\"u#{r[0]}.html\">#{r[1]}</a></td><td>#{teams[r[3]-1][1]}</td><td>#{r[2].round(2)}</td><td>#{r[4].round(2)}</td></tr>\n"
    else
        prolog += "<tr class=\"alt\"><td><a href=\"u#{r[0]}.html\">#{r[1]}</a></td><td>#{teams[r[3]-1][1]}</td><td>#{r[2].round(2)}</td><td>#{r[4].round(2)}</td></tr>\n"
    end
    odd = !odd
end

prolog += "</tbody>\n"
prolog += "</table></div>\n"

File.open('html/index.html', 'w') { |f| f.write(index_erb.result) }
File.open('html/rules.html', 'w') { |f| f.write(rules_erb.result) }

data = ""
runners = db.execute("SELECT * FROM runners") do |r|
    data = ""
    data += "<center>\n"
    data += "<h1>Карточка участника</h1>\n"
    data += "</center>\n"
    data += "<div class=\"datagrid\">\n"
    data += "<table>\n"
    data += "<tbody>\n"
    data += "<tr><td><b>Имя</b></td><td>#{r[1]}</td></tr>"
    data += "<tr><td><b>Команда</b></td><td>#{teams[r[2]-1][1]}</td></tr>"
    data += "<tr><td><b>Недельный план</b></td><td>#{(7*r[3]/365).round(2)}</td></tr>"
    data += "</tbody>\n"
    data += "</table>\n"

    File.open("html/u#{r[0]}.html", 'w') { |f| f.write(user_erb.result) }
end
