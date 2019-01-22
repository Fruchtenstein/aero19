#!/usr/bin/ruby -W0
require 'sqlite3'
require 'active_support'
require 'active_support/core_ext'
require 'erb'
require 'gnuplot'
require_relative './config.rb'

def printweek (w)
    output = ""
    db = SQLite3::Database.new("2019.db")
    teams = db.execute("SELECT teams.teamid, points, pcts, teamname  FROM points,teams WHERE points.teamid=teams.teamid AND week=#{w} ORDER BY points DESC")
    output +=   "<center>\n"
    output +=   "    <br />\n"
    p "printweek: #{w}; #{Date.today.cweek}; #{Date.today.wday}; #{DOW}\n"
    if w==Date.today.cweek or (w==Date.today.cweek-1 and Date.today.wday.between?(1, DOW-1))
        output +=   "    <h1>Предварительные результаты #{w} недели</h1>\n"
    else
        output +=   "    <h1>Результаты #{w} недели</h1>\n"
    end
    output +=   "    <!--a href=\"teams#{w}.html\">Подробнее</a-->\n"
    output +=   "    <br />\n"
    output +=   "</center>\n"
    output +=   "<div class=\"datagrid\"><table>\n"
    output +=   "   <thead><tr><th>Команда</th><th>Выполнено (%)</th><th>Очки</th><th>Сумма</th></tr></thead>\n"
    output += "<tbody>\n\n"
    odd = true
    teams.each do |t|
        p t
        sum = db.execute("SELECT SUM(points) FROM points WHERE teamid=#{t[0]} AND week<=#{w}")[0]
        if odd
            output += "  <tr><td>#{t[3]}</td><td>#{t[2].round(2)}</td><td>#{t[1]}</td><td>#{sum[0]}</td></tr>\n"
        else
            output += "  <tr class=\"alt\"><td>#{t[3]}</td><td>#{t[2].round(2)}</td><td>#{t[1]}</td><td>#{sum[0]}</td></tr>\n"
        end
        odd = !odd
    end
    output +=   "   </tbody>\n"
    output +=   "</table>\n"
    output +=   "</div>\n"
    return output
end


$stdout.sync = true
now = Time.now.getutc
if now < STARTPROLOG or now > ENDCUP
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
statistics_erb = ERB.new(File.read('statistics.html.erb'))

db = SQLite3::Database.new("2019.db")

### Process index.html
if now > STARTPROLOG #and now < 7.days.after(CLOSEPROLOG)
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
    if Date.today.wday.between?(1, DOW-1)
        teams = db.execute("SELECT teams.teamid, teamname, COALESCE(SUM(points),0) AS p FROM points, teams WHERE points.teamid=teams.teamid AND week<#{w-1} GROUP BY teams.teamid ORDER BY p DESC")
    else
        teams = db.execute("SELECT teams.teamid, teamname, COALESCE(SUM(points),0) AS p FROM points, teams WHERE points.teamid=teams.teamid AND week<#{w} GROUP BY teams.teamid ORDER BY p DESC")
    end
    champ +=   "<center>\n"
    champ +=   "    <br />\n"
    champ +=   "    <h1>Текущее положение команд</h1>\n"
    champ +=   "    <br />\n"
    champ +=   "</center>\n"
    champ +=   "<div class=\"datagrid\"><table>\n"
    champ +=   "   <thead><tr><th>Команда</th><th>Очки</th></tr></thead>\n"
    champ +=   "    <tbody>\n"
    odd = true
    teams.each do |t|
        if odd
            champ += "  <tr><td>#{t[1]}</td><td>#{t[2]}</td></tr>\n"
        else
            champ += "  <tr class=\"alt\"><td>#{t[1]}</td><td>#{t[2]}</td></tr>\n"
        end
        odd = !odd
    end
    champ +=   "   </tbody>\n"
    champ +=   "</table>\n"
    champ +=   "</div>\n"
    champ +=   "<br />\n"
    champ += printweek w
    champ +=   "<br />\n"
    [*STARTCHM.to_date.cweek..(Date.today.cweek-1)].reverse_each do |w|
         p w
         champ += printweek w
    end
end

File.open('html/index.html', 'w') { |f| f.write(index_erb.result) }
File.open('html/rules.html', 'w') { |f| f.write(rules_erb.result) }

### Process users' personal pages
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

### Process users.html
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
    data += "<thead><tr><th>Имя</th><th>Объемы 2018 (км/год)</th><th>Примечания</th></tr></thead>\n"
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

### Process teams*.html
[*STARTCHM.to_date.cweek..(Date.today.cweek)].reverse_each do |w|
     puts "teams#{w}...."
     p w
     bow = DateTime.parse(Date.commercial(2019,w).to_s).beginning_of_week
     eow = DateTime.parse(Date.commercial(2019,w).to_s).end_of_week
     p bow.iso8601, eow.iso8601
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
         data +=   "    <tbody>\n"
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
                 data += "  <tr><td><a href=\"u#{r[0]}.html\">#{r[1]}</a></td><td>#{goal.round(2)}</td><td>#{dist.round(2)}</td><td>#{pct.round(2)}</td></tr>\n"
             else
                 data += "  <tr class=\"alt\"><td><a href=\"u#{r[0]}.html\">#{r[1]}</a></td><td>#{goal.round(2)}</td><td>#{dist.round(2)}</td><td>#{pct.round(2)}</td></tr>\n"
             end
             odd = !odd
         end
         data +=  "<tfoot><tr><td>Всего:</td><td>#{sum_goal.round(2)}</td><td>#{sum_dist.round(2)}</td><td>#{(sum_pct/runners.length).round(2)}</td></tr></tfoot>\n"
         data +=   "   </tbody>\n"
         data +=   "</table>\n"
         data +=   "</div>\n"
     end
     box  = "<nav class=\"sub\">\n"
     box += "      <ul>\n"
     (STARTCHM.to_date.cweek..Date.today.cweek).each do |wk|
         if wk == w
             box += "        <li class=\"active\"><span>#{wk} неделя</span></li>\n"
         else
             box += "        <li><a href=\"teams#{wk}.html\">#{wk} неделя</a></li>\n"
         end
     end
     box += "      </ul>\n"
     box += "    </nav>\n"
     File.open("html/teams#{w}.html", 'w') { |f| f.write(teams_erb.result(binding)) }
end

### Process statistics*.html
[*STARTCHM.to_date.cweek..(Date.today.cweek)].reverse_each do |w|
     puts "statistics#{w}...."
     p w
     bow = DateTime.parse(Date.commercial(2019,w).to_s).beginning_of_week
     eow = DateTime.parse(Date.commercial(2019,w).to_s).end_of_week
     p bow.iso8601, eow.iso8601
     data = ""
     data +=   "<center>\n"
     data +=   "    <br />\n"
     data +=   "    <br />\n"
     data +=   "    <h1>Чудеса недели</h1>\n"
     data +=   "</center>\n"
     data +=   "<div class=\"datagrid\"><table>\n"
     data +=   "   <thead><tr><th></th><th>Имя</th><th>Команда</th><th>Результат (км)</th></tr></thead>\n"
     data +=   "    <tbody>\n"

     x = db.execute("SELECT l.runnerid, runnername, MAX(d), teamname FROM \
                         (SELECT runnerid, SUM(distance) d FROM log \
                                WHERE date>'#{bow.iso8601}' AND date<'#{eow.iso8601}' GROUP BY runnerid) l, runners, teams \
                                    WHERE runners.runnerid=l.runnerid AND teams.teamid=runners.teamid")[0]
     p x
     x[0] = x[0] || 0
     x[1] = x[1] || ''
     x[2] = x[2] || 0
     x[3] = x[3] || ''
#     data +=   "</center>\n"
     data +=   "    <tr><td>Больше всех километров</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[3]}</td><td>#{x[2].round(2)} км</td></tr>\n"

     x = db.execute("SELECT l.runnerid, runnername, MAX(d), teamname FROM \
                         (SELECT runnerid, SUM(distance) d FROM log \
                                WHERE date>'#{bow.iso8601}' AND date<'#{eow.iso8601}' GROUP BY runnerid) l, runners, teams \
                                    WHERE runners.runnerid=l.runnerid AND sex=0 AND teams.teamid=runners.teamid")[0]
     p x
     x[0] = x[0] || 0
     x[1] = x[1] || ''
     x[2] = x[2] || 0
     x[3] = x[3] || ''
#     data +=   "</center>\n"
     data +=   "    <tr class='alt'><td>Больше всех километров среди женщин</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[3]}</td><td>#{x[2].round(2)} км</td></tr>\n"

     x = db.execute("SELECT l.runnerid, runnername, MAX(d), teamname FROM \
                        (SELECT runnerid, 100*SUM(distance)/(SELECT 7*goal/365 FROM runners WHERE runnerid=log.runnerid) d \
                                FROM log WHERE date>'#{bow.iso8601}' AND date<'#{eow.iso8601}' GROUP BY runnerid) l, runners, teams \
                                    WHERE runners.runnerid=l.runnerid AND teams.teamid=runners.teamid")[0]
     p x
     x[0] = x[0] || 0
     x[1] = x[1] || ''
     x[2] = x[2] || 0
     x[3] = x[3] || ''
     data +=   "    <tr><td>Больше всех процентов</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[3]}</td><td>#{x[2].round(2)}%</td></tr>\n"

     x = db.execute("SELECT l.runnerid, runnername, MAX(d), teamname FROM \
                        (SELECT runnerid, 100*SUM(distance)/(SELECT 7*goal/365 FROM runners WHERE runnerid=log.runnerid) d \
                                FROM log WHERE date>'#{bow.iso8601}' AND date<'#{eow.iso8601}' GROUP BY runnerid) l, runners, teams \
                                    WHERE runners.runnerid=l.runnerid AND sex=0 AND teams.teamid=runners.teamid")[0]
     p x
     x[0] = x[0] || 0
     x[1] = x[1] || ''
     x[2] = x[2] || 0
     x[3] = x[3] || ''
     data +=   "    <tr class='alt'><td>Больше всех процентов среди женщин</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[3]}</td><td>#{x[2].round(2)}%</td></tr>\n"

     x = db.execute("SELECT log.runnerid, runnername, MAX(distance), runid, teamname FROM log, runners, teams WHERE date>'#{bow.iso8601}' AND date<'#{eow.iso8601}' AND runners.runnerid=log.runnerid AND teams.teamid=runners.teamid")[0]
     p x
     x[0] = x[0] || 0
     x[1] = x[1] || ''
     x[2] = x[2] || 0
     x[3] = x[3] || 0
     x[4] = x[4] || ''
     data +=   "    <tr><td>Самая длинная тренировка</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[4]}</td><td><a href='http://aerobia.ru/users/#{x[0]}/workouts/#{x[3]}'>#{x[2].round(2)} км</a></td></tr>\n"

     x = db.execute("SELECT log.runnerid, runnername, MAX(distance), runid, teamname FROM log, runners, teams WHERE date>'#{bow.iso8601}' AND date<'#{eow.iso8601}' AND runners.runnerid=log.runnerid AND sex=0 AND teams.teamid=runners.teamid")[0]
     p x
     x[0] = x[0] || 0
     x[1] = x[1] || ''
     x[2] = x[2] || 0
     x[3] = x[3] || 0
     x[4] = x[4] || ''
     data +=   "    <tr class='alt'><td>Самая длинная тренировка у женщин</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[4]}</td><td><a href='http://aerobia.ru/users/#{x[0]}/workouts/#{x[3]}'>#{x[2].round(2)} км</a></td></tr>\n"

     x = db.execute("SELECT log.runnerid, runnername, strftime('%M:%S',MIN(time/distance),'unixepoch'), runid, distance, teamname FROM log, runners, teams WHERE log.runnerid=runners.runnerid AND date>'#{bow.iso8601}' AND date<'#{eow.iso8601}' AND teams.teamid=runners.teamid AND time>0")[0]
     p x
     x[0] = x[0] || 0
     x[1] = x[1] || ''
     x[2] = x[2] || 0
     x[3] = x[3] || 0
     x[4] = x[4] || 0
     x[5] = x[5] || ''
     data +=   "    <tr><td>Самая быстрая тренировка</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[5]}</td><td><a href='http://aerobia.ru/users/#{x[0]}/workouts/#{x[3]}'>#{x[2]} мин/км (#{x[4].round(2)} км)</a></td></tr>\n"

     x = db.execute("SELECT log.runnerid, runnername, strftime('%M:%S',MIN(time/distance),'unixepoch'), runid, distance, teamname FROM log, runners, teams WHERE log.runnerid=runners.runnerid AND date>'#{bow.iso8601}' AND date<'#{eow.iso8601}' AND sex=0 AND teams.teamid=runners.teamid AND time>0")[0]
     p x
     x[0] = x[0] || 0
     x[1] = x[1] || ''
     x[2] = x[2] || 0
     x[3] = x[3] || 0
     x[4] = x[4] || 0
     x[5] = x[5] || ''
     data +=   "    <tr><td>Самая быстрая тренировка у женщин</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[5]}</td><td><a href='http://aerobia.ru/users/#{x[0]}/workouts/#{x[3]}'>#{x[2]} мин/км (#{x[4].round(2)} км)</a></td></tr>\n"

     x = db.execute("SELECT l.runnerid, runnername, strftime('%M:%S',MIN(t/d),'unixepoch'), teamname FROM (SELECT runnerid, SUM(time) t, SUM(distance) d FROM log WHERE date>'#{bow.iso8601}' AND date<'#{eow.iso8601}' AND time>0 GROUP BY runnerid) l, runners, teams WHERE runners.runnerid=l.runnerid AND teams.teamid=runners.teamid")[0]
     p x
     x[0] = x[0] || 0
     x[1] = x[1] || ''
     x[2] = x[2] || 0
     x[3] = x[3] || ''
     data +=   "    <tr><td>Самая быстрый средний темп</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[3]}</td><td>#{x[2]} мин/км</td></tr>\n"

     x = db.execute("SELECT l.runnerid, runnername, strftime('%M:%S',MIN(t/d),'unixepoch'), teamname FROM (SELECT runnerid, SUM(time) t, SUM(distance) d FROM log WHERE date>'#{bow.iso8601}' AND date<'#{eow.iso8601}' AND time>0 GROUP BY runnerid) l, runners, teams WHERE runners.runnerid=l.runnerid AND sex=0 AND teams.teamid=runners.teamid")[0]
     p x
     x[0] = x[0] || 0
     x[1] = x[1] || ''
     x[2] = x[2] || 0
     x[3] = x[3] || ''
     data +=   "    <tr><td>Самая быстрый средний темп у женщин</td><td><a href='http://aerobia.net/u#{x[0]}.html'>#{x[1]}</a></td><td>#{x[3]}</td><td>#{x[2]} мин/км</td></tr>\n"

     data +=   "   </tbody>\n"
     data +=   "</table>\n"
     data +=   "</div>\n"
     data +=   "<br />\n"

     box  = "<nav class=\"sub\">\n"
     box += "      <ul>\n"
     (STARTCHM.to_date.cweek..Date.today.cweek).each do |wk|
         if wk == w
             box += "        <li class=\"active\"><span>#{wk} неделя</span></li>\n"
         else
             box += "        <li><a href=\"statistics#{wk}.html\">#{wk} неделя</a></li>\n"
         end
     end
     box += "      </ul>\n"
     box += "    </nav>\n"
     File.open("html/statistics#{w}.html", 'w') { |f| f.write(statistics_erb.result(binding)) }
end

(STARTCHM.to_date.cweek..Date.today.cweek).each do |w|
    p "plot for week #{w}"
    Gnuplot.open do |gp|
        Gnuplot::Plot.new(gp) do |plot|
            plot.terminal "png"
            plot.output File.expand_path("../html/cup#{w}.png", __FILE__)
            plot.title 'Кубок'
	    plot.key "bmargin"
            weeks = db.execute("SELECT DISTINCT week FROM points WHERE week <= #{w} ORDER BY week").map { |i| i[0] }
            plot.xrange "[1:#{weeks[-1]}]"
            plot.xlabel 'Недели'
            plot.ylabel 'Очки'
            plot.ytics ''
            plot.grid 'y'
            (1..TEAMS).each do |t|
                team = db.execute("SELECT teamname FROM teams WHERE teamid=#{t}")[0][0]
                a = [0] + db.execute("SELECT teamid, week, (SELECT SUM(points) FROM points WHERE week<=p.week AND teamid=p.teamid) FROM points p WHERE teamid=#{t} AND week <= #{w} ORDER BY week").map { |i| i[2] }
                p weeks, a
		plot.data << Gnuplot::DataSet.new( a ) do |ds|
		    ds.with = "lines"
		    ds.linewidth = 3
		    ds.title = team
		end
	    end
	end
    end
end

