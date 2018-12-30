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

db = SQLite3::Database.new("2019.db")

prolog += "<center>\n"
prolog += "<h1>Пролог</h1>\n"
prolog += "</center>\n"
prolog += "<div class=\"datagrid\">\n"
prolog += "<table>\n"
prolog += "<thead><tr><th>Имя</th><th>Цель2018 (км)</th><th>Результат (км)</th></tr></thead>\n"
prolog += "<tbody>\n"

index_erb = ERB.new(File.read('index.html.erb'))

odd = true
db.execute("SELECT runners.runnerid,runners.runnername,7*runners.goal/365,COALESCE(SUM(log.distance),0) AS dist FROM log JOIN runners ON log.runnerid=runners.runnerid AND date>'#{STARTPROLOG.iso8601}' AND date<'#{ENDPROLOG.iso8601}' GROUP BY log.runnerid ORDER BY dist DESC").each do |r|
#    log = db.execute("SELECT COALESCE(SUM(distance),0) AS dist FROM log WHERE runnerid=#{r[0]} AND date>'#{STARTPROLOG.iso8601}' AND date<'#{ENDPROLOG.iso8601}'")
    if odd then
        prolog += "<tr><td>#{r[1]}</td><td>#{r[2].round(2)}</td><td>#{r[3].round(2)}</td></tr>\n"
    else
        prolog += "<tr class=\"alt\"><td>#{r[1]}</td><td>#{r[2].round(2)}</td><td>#{r[3].round(2)}</td></tr>\n"
    end
    odd = !odd
end

prolog += "</tbody>\n"
prolog += "</table></div>\n"

File.open('html/index.html', 'w') { |f| f.write(index_erb.result) }


