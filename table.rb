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
champ = ""
cup = ""


index_erb = ERB.new(File.read('index.html.erb'))
rules_erb = ERB.new(File.read('rules.html.erb'))
teams_erb = ERB.new(File.read('teams.html.erb'))
user_erb = ERB.new(File.read('u.html.erb'))
users_erb = ERB.new(File.read('users.html.erb'))

db = SQLite3::Database.new("2019.db")

if now > STARTPROLOG and now < 7.days.after(CLOSEPROLOG)
    prolog += "<center>\n"
    prolog += "<h1>Пролог (неделя 1)</h1>\n"
    prolog += "</center>\n"
    prolog += "<div class=\"datagrid\">\n"
    prolog += "<table>\n"
    prolog += "<thead><tr><th>Имя</th><th>Команда</th><th>Объемы 2018 (км/нед)</th><th>Результат (км)</th></tr></thead>\n"
    prolog += "<tbody>\n"
    
    teams = db.execute("SELECT * FROM teams")
    
    odd = true
    runners = db.execute("SELECT runnerid,runnername,7*goal/365,teamid FROM runners")
    runners.each do |r|
        r << db.execute("SELECT COALESCE(SUM(distance),0) AS dist FROM log WHERE runnerid=#{r[0]} AND date>'#{STARTPROLOG.iso8601}' AND date<'#{ENDPROLOG.iso8601}'")[0][0]
    end
    runners.sort! { |x,y| y[4] <=> x[4] }
    runners.each do |r|
#        if now > CLOSEPROLOG
#            points = case runners.index(r)
#                     when 0 then 20
#                     when 1 then 10
#                     when 2 then 5
#                     else 0
#                     end
#        else
#            points = 0
#        end
        if odd then
            prolog += "<tr><td><a href=\"u#{r[0]}.html\">#{r[1]}</a></td><td>#{teams[r[3]-1][1]}</td><td>#{r[2].round(2)}</td><td>#{r[4].round(2)}</td></tr>\n"
        else
            prolog += "<tr class=\"alt\"><td><a href=\"u#{r[0]}.html\">#{r[1]}</a></td><td>#{teams[r[3]-1][1]}</td><td>#{r[2].round(2)}</td><td>#{r[4].round(2)}</td></tr>\n"
        end
        odd = !odd
    end
    
    prolog += "</tbody>\n"
    prolog += "</table></div>\n"
end

if now > STARTCHM
    w = Date.today.cweek
    p w
    teams = db.execute("SELECT teams.teamid, teamname, COALESCE(SUM(points),0) AS p FROM points, teams WHERE points.teamid=teams.teamid AND week<#{w} GROUP BY teams.teamid ORDER BY p DESC")
    champ +=   "<center>"
    champ +=   "    <h1>Текущее положение команд</h1>"
    champ +=   "    <br />"
    champ +=   "    <br />"
    champ +=   "</center>"
    champ +=   "<div class=\"datagrid\"><table>"
    champ +=   "   <thead><tr><th>Команда</th><th>Очки</th></tr></thead>"
    odd = true
    teams.each do |t|
        if odd
            champ += "  <tr><td>#{t[1]}</td><td>#{t[2]}</td></tr>"
        else
            champ += "  <tr class=\"alt\"><td>#{t[1]}</td><td>#{t[2]}</td></tr>"
        end
        odd = !odd
    end
    champ +=   "   </tbody>"
    champ +=   "</table>"
    champ +=   "</div>"
    champ +=   "<br />"
    teams = db.execute("SELECT teams.teamid, points, pcts, teamname  FROM points,teams WHERE points.teamid=teams.teamid AND week=#{w} ORDER BY points DESC")
    champ +=   "<center>"
    champ +=   "    <h1>Предварительные результаты #{w} недели</h1>"
    champ +=   "    <!--a href=\"teams#{w}.html\">Подробнее</a-->"
    champ +=   "    <br />"
    champ +=   "    <br />"
    champ +=   "</center>"
    champ +=   "<div class=\"datagrid\"><table>"
    champ +=   "   <thead><tr><th>Команда</th><th>Выполнено (%)</th><th>Очки</th><th>Сумма</th></tr></thead>"
    odd = true
    teams.each do |t|
        p t
        sum = db.execute("SELECT SUM(points) FROM points WHERE teamid=#{t[0]} AND week<=#{w}")[0]
        if odd
            champ += "  <tr><td>#{t[3]}</td><td>#{t[2].round(2)}</td><td>#{t[1]}</td><td>#{sum[0]}</td></tr>"
        else
            champ += "  <tr class=\"alt\"><td>#{t[3]}</td><td>#{t[2].round(2)}</td><td>#{t[1]}</td><td>#{sum[0]}</td></tr>"
        end
        odd = !odd
    end
    champ +=   "   </tbody>"
    champ +=   "</table>"
    champ +=   "</div>"
    champ +=   "<br />"
    [*STARTCHM.to_date.cweek..(Date.today.cweek-1)].reverse_each do |w|
         p w
         teams = db.execute("SELECT teams.teamid, points, pcts, teamname  FROM points,teams WHERE points.teamid=teams.teamid AND week=#{w} ORDER BY points DESC")
         champ +=   "<center>"
         champ +=   "    <h1>Результаты #{w} недели</h1>"
         champ +=   "    <!--a href=\"teams#{w}.html\">Подробнее</a-->"
         champ +=   "    <br />"
         champ +=   "    <br />"
         champ +=   "</center>"
         champ +=   "<div class=\"datagrid\"><table>"
         champ +=   "   <thead><tr><th>Команда</th><th>Выполнено (%)</th><th>Очки</th><th>Сумма</th></tr></thead>"
         odd = true
         teams.each do |t|
             p t
             sum = db.execute("SELECT SUM(points) FROM points WHERE teamid=#{t[0]} AND week<=#{w}")[0]
             if odd
                 champ += "  <tr><td>#{t[3]}</td><td>#{t[2]}</td><td>#{t[1]}</td><td>#{sum[0]}</td></tr>"
             else
                 champ += "  <tr class=\"alt\"><td>#{t[3]}</td><td>#{t[2]}</td><td>#{t[1]}</td><td>#{sum[0]}</td></tr>"
             end
             odd = !odd
         end
         champ +=   "   </tbody>"
         champ +=   "</table>"
         champ +=   "</div>"
    end
end

File.open('html/index.html', 'w') { |f| f.write(index_erb.result) }
File.open('html/rules.html', 'w') { |f| f.write(rules_erb.result) }

data = ""
runners = db.execute("SELECT * FROM runners ORDER BY runnername")
teams = db.execute("SELECT * FROM teams")
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


[*STARTCHM.to_date.cweek..(Date.today.cweek)].reverse_each do |w|
     puts "teams#{w}...."
     p w
     bow = DateTime.parse(Date.commercial(2019,w).to_s).beginning_of_week
     eow = DateTime.parse(Date.commercial(2019,w).to_s).end_of_week
     p bow, eow
     teams = db.execute("SELECT * FROM teams")
     data = ""
     db.execute("SELECT * FROM teams") do |t|
         p t
         data +=   "<center>\n"
         data +=   "    <br />\n"
         data +=   "    <br />\n"
         data +=   "    <h1>#{t[1]}</h1>\n"
         data +=   "</center>\n"
         data +=   "<div class=\"datagrid\"><table>\n"
         data +=   "   <thead><tr><th>Имя</th><th>Цель (км/нед)</th><th>Результат (км)</th><th>Выполнено (%)</th></tr></thead>\n"
         sum_dist = 0
         sum_pct = 0
         sum_goal = 0
         odd = true
         runners = db.execute("SELECT * FROM runners WHERE teamid=#{t[0]} ORDER BY goal DESC")
         runners.each do |r|
             dist = db.execute("SELECT COALESCE(SUM(distance),0) FROM log WHERE runnerid=#{r[0]} AND date>'#{bow.iso8601}' AND date<'#{eow.iso8601}'")[0][0]
             goal = 7*r[3]/365
             pct = (dist/goal)*100
             sum_dist += dist
             sum_pct += pct
             sum_goal += goal
             if odd
                 data += "  <tr><td>#{r[1]}</td><td>#{goal.round(2)}</td><td>#{dist.round(2)}</td><td>#{pct.round(2)}</td></tr>\n"
             else
                 data += "  <tr class=\"alt\"><td>#{r[1]}</td><td>#{goal.round(2)}</td><td>#{dist.round(2)}</td><td>#{pct.round(2)}</td></tr>\n"
             end
             odd = !odd
         end
         data +=  "<tfoot><tr><td>Всего:</td><td>#{sum_goal.round(2)}</td><td>#{sum_dist.round(2)}</td><td>#{(sum_pct/runners.length).round(2)}</td></tr></tfoot>"
#         data +=   "   </tbody>\n"
         data +=   "</table>\n"
         data +=   "</div>\n"
     end
     File.open("html/teams#{w}.html", 'w') { |f| f.write(teams_erb.result(binding)) }
end
