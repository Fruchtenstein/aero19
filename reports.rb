require 'sqlite3'
require 'active_support'
require 'active_support/core_ext'

bow = 1.week.ago.beginning_of_week.iso8601
eow = 1.week.ago.end_of_week.iso8601
#r = "select runnername,sum(distance) d,log.runnerid from log,runners where date>'#{bow}' and date<'#{eow}' and log.runnerid=runners.runnerid group by log.runnerid order by d desc limit 5"
#puts r
puts "самая длинная неделя"
r = `litecli 2019.db -te "select log.runnerid, runnername,sum(distance) d from log,runners where date>'#{bow}' and date<'#{eow}' and log.runnerid=runners.runnerid group by log.runnerid order by d desc limit 5"`
puts r
r = `litecli 2019.db -te "select log.runnerid, runnername,sum(distance) d from log,runners where date>'#{bow}' and date<'#{eow}' and log.runnerid=runners.runnerid and sex=0 group by log.runnerid order by d desc limit 5"`
puts r
puts "самая длинная пробежка"
r = `litecli 2019.db -te "select log.runnerid, runnername,date,distance,'http://aerobia.ru/users/'|| log.runnerid||'/workouts/'||runid from log,runners where date>'#{bow}' and date<'#{eow}' and log.runnerid=runners.runnerid order by distance desc limit 5"` 
puts r
r = `litecli 2019.db -te "select log.runnerid, runnername,date,distance,'http://aerobia.ru/users/'|| log.runnerid||'/workouts/'||runid from log,runners where date>'#{bow}' and date<'#{eow}' and log.runnerid=runners.runnerid and sex=0 order by distance desc limit 5"` 
puts r
puts "самая продолжительная пробежка"
r = `litecli 2019.db -te "select log.runnerid, runnername,date,time, strftime('%H:%M:%S',time,'unixepoch') duration,'http://aerobia.ru/users/'|| log.runnerid||'/workouts/'||runid from log,runners where date>'#{bow}' and date<'#{eow}' and log.runnerid=runners.runnerid order by time desc limit 5"` 
puts r
r = `litecli 2019.db -te "select log.runnerid, runnername,date,time, strftime('%H:%M:%S',time,'unixepoch') duration,'http://aerobia.ru/users/'|| log.runnerid||'/workouts/'||runid from log,runners where date>'#{bow}' and date<'#{eow}' and log.runnerid=runners.runnerid and sex=0 order by time desc limit 5"` 
puts r
puts "самая быстрая пробежка"
r = `litecli 2019.db -te "select log.runnerid, runnername,date,strftime('%M:%S',time/distance,'unixepoch') pace,distance, 'http://aerobia.ru/users/'|| log.runnerid||'/workouts/'||runid from log,runners where date>'#{bow}' and date<'#{eow}' and log.runnerid=runners.runnerid order by pace limit 5"`
puts r
r = `litecli 2019.db -te "select log.runnerid, runnername,date,strftime('%M:%S',time/distance,'unixepoch') pace,distance, 'http://aerobia.ru/users/'|| log.runnerid||'/workouts/'||runid from log,runners where date>'#{bow}' and date<'#{eow}' and log.runnerid=runners.runnerid and sex=0 order by pace limit 5"`
puts r
puts "больше всего процентов"
r = `litecli 2019.db -te "select l.runnerid, runnername, d, teamname from (select runnerid, 100*sum(distance)/(select 7*goal/365 from runners where runnerid=log.runnerid) d from log where date>'#{bow}' and date<'#{eow}' group by runnerid) l, runners, teams where runners.runnerid=l.runnerid and teams.teamid=runners.teamid order by d DESC limit 5"`
puts r
r = `litecli 2019.db -te "select l.runnerid, runnername, d, teamname from (select runnerid, 100*sum(distance)/(select 7*goal/365 from runners where runnerid=log.runnerid) d from log where date>'#{bow}' and date<'#{eow}' group by runnerid) l, runners, teams where runners.runnerid=l.runnerid and sex=0 and teams.teamid=runners.teamid order by d DESC limit 5"`
puts r
puts "самая медленная пробежка"
r = `litecli 2019.db -te "select log.runnerid, runnername,date,strftime('%M:%S',time/distance,'unixepoch') pace,distance, 'http://aerobia.ru/users/'|| log.runnerid||'/workouts/'||runid from log,runners where date>'#{bow}' and date<'#{eow}' and log.runnerid=runners.runnerid order by pace DESC limit 10"`
puts r
r = `litecli 2019.db -te "select log.runnerid, runnername,date,strftime('%M:%S',time/distance,'unixepoch') pace,distance, 'http://aerobia.ru/users/'|| log.runnerid||'/workouts/'||runid from log,runners where date>'#{bow}' and date<'#{eow}' and log.runnerid=runners.runnerid and sex=0 order by pace DESC limit 5"`
puts r
puts "самая быстрая неделя"
r = `litecli 2019.db -te "SELECT l.runnerid, runnername, strftime('%M:%S',t/d,'unixepoch') pace, teamname FROM (SELECT runnerid, SUM(time) t, SUM(distance) d FROM log WHERE date>'#{bow}' AND date<'#{eow}' AND time>0 GROUP BY runnerid) l, runners, teams WHERE runners.runnerid=l.runnerid AND teams.teamid=runners.teamid ORDER BY pace LIMIT 5"`
puts r
r = `litecli 2019.db -te "SELECT l.runnerid, runnername, strftime('%M:%S',t/d,'unixepoch') pace, teamname FROM (SELECT runnerid, SUM(time) t, SUM(distance) d FROM log WHERE date>'#{bow}' AND date<'#{eow}' AND time>0 GROUP BY runnerid) l, runners, teams WHERE runners.runnerid=l.runnerid AND sex=0 AND teams.teamid=runners.teamid ORDER BY pace LIMIT 5"`
puts r
puts "самая медленная неделя"
r = `litecli 2019.db -te "SELECT l.runnerid, runnername, strftime('%M:%S',t/d,'unixepoch') pace, teamname FROM (SELECT runnerid, SUM(time) t, SUM(distance) d FROM log WHERE date>'#{bow}' AND date<'#{eow}' AND time>0 GROUP BY runnerid) l, runners, teams WHERE runners.runnerid=l.runnerid AND teams.teamid=runners.teamid ORDER BY pace DESC LIMIT 5"`
puts r
r = `litecli 2019.db -te "SELECT l.runnerid, runnername, strftime('%M:%S',t/d,'unixepoch') pace, teamname FROM (SELECT runnerid, SUM(time) t, SUM(distance) d FROM log WHERE date>'#{bow}' AND date<'#{eow}' AND time>0 GROUP BY runnerid) l, runners, teams WHERE runners.runnerid=l.runnerid AND sex=0 AND teams.teamid=runners.teamid ORDER BY pace DESC LIMIT 5"`
puts r
