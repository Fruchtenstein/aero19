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
users_erb = ERB.new(File.read('users.html.erb'))

db = SQLite3::Database.new("2019.db")

if now > STARTPROLOG and now <7.days.after(CLOSEPROLOG)
    prolog += "<center>\n"
    prolog += "<h1>Пролог</h1>\n"
    prolog += "</center>\n"
    prolog += "<div class=\"datagrid\">\n"
    prolog += "<table>\n"
    prolog += "<thead><tr><th>Имя</th><th>Команда</th><th>Объемы 2018 (км/нед)</th><th>Результат (км)</th><th>Очки</th></tr></thead>\n"
    prolog += "<tbody>\n"
    
    teams = db.execute("SELECT * FROM teams")
    
    odd = true
    runners = db.execute("SELECT runnerid,runnername,7*goal/365,teamid FROM runners")
    runners.each do |r|
        r << db.execute("SELECT COALESCE(SUM(distance),0) AS dist FROM log WHERE runnerid=#{r[0]} AND date>'#{STARTPROLOG.iso8601}' AND date<'#{ENDPROLOG.iso8601}'")[0][0]
    end
    runners.sort! { |x,y| y[4] <=> x[4] }
    runners.each do |r|
        if now > CLOSEPROLOG
            points = case runners.index(r)
                     when 0 then 20
                     when 1 then 10
                     when 2 then 5
                     else 0
                     end
        else
            points = 0
        end
        if odd then
            prolog += "<tr><td><a href=\"u#{r[0]}.html\">#{r[1]}</a></td><td>#{teams[r[3]-1][1]}</td><td>#{r[2].round(2)}</td><td>#{r[4].round(2)}</td><td>#{points}</td></tr>\n"
        else
            prolog += "<tr class=\"alt\"><td><a href=\"u#{r[0]}.html\">#{r[1]}</a></td><td>#{teams[r[3]-1][1]}</td><td>#{r[2].round(2)}</td><td>#{r[4].round(2)}</td><td>#{points}</td></tr>\n"
        end
        odd = !odd
    end
    
    prolog += "</tbody>\n"
    prolog += "</table></div>\n"
end

File.open('html/index.html', 'w') { |f| f.write(index_erb.result) }
File.open('html/rules.html', 'w') { |f| f.write(rules_erb.result) }

data = ""
runners = db.execute("SELECT * FROM runners ORDER BY runnername")
runners.each do |r|
    note = db.execute("SELECT title FROM titles WHERE runnerid=#{r[0]}").join("<br />")
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
    data += "<tr><td><b>Достижения</b></td><td>#{note}</td></tr>"
    data += "<tr><td><b>Профиль на Аэробии</b></td><td><a href=\"http://aerobia.ru/users/#{r[0]}\">http://aerobia.ru/users/#{r[0]}</a></td></tr>"
    data += "</tbody>\n"
    data += "</table>\n"

    File.open("html/u#{r[0]}.html", 'w') { |f| f.write(user_erb.result(binding)) }
end
data = ""
data += "<center>\n"
data += "<h1>Команды и участники</h1>\n"
data += "</center>\n"
db.execute("SELECT * FROM teams ORDER BY teamid") do |t|
    data += "<center>\n"
    data += "<h2>#{t[1]}</h1>\n"
    data += "</center>\n"
    data += "<div class=\"datagrid\">\n"
    data += "<table>\n"
    data += "<tbody>\n"
    data += "<thead><tr><th>Имя</th><th>Объемы 2018 (км/год)</th><th>Примечания</th></tr></thead>"
    odd = true
    db.execute("SELECT * FROM runners WHERE teamid=#{t[0]} ORDER BY goal DESC") do |r|
        note = db.execute("SELECT title FROM titles WHERE runnerid=#{r[0]}").join("<br />")
        if odd
            data += "<tr><td><a href=\"u#{r[0]}.html\">#{r[1]}</a></td><td>#{r[3].round(2)}</td><td>#{note}</td></tr>\n"
        else
            data += "<tr class=\"alt\"><td><a href=\"u#{r[0]}.html\">#{r[1]}</a></td><td>#{r[3].round(2)}</td><td>#{note}</td></tr>\n"
        end
        odd = !odd
    end
    data += "</tbody>\n"
    data += "</table>\n"
    data += "</div>\n"
    data += "<br />\n"
end
File.open("html/users.html", 'w') { |f| f.write(users_erb.result(binding)) }
