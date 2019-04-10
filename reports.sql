-- самая длинная неделя
select runnername,sum(distance) d,log.runnerid from log,runners where date>'2019-04-01T00:00:00Z' and date<'2019-04-07T23:59:59Z' and log.runnerid=runners.runnerid group by log.runnerid order by d desc limit 5;
select runnername,sum(distance) d,log.runnerid from log,runners where date>'2019-04-01T00:00:00Z' and date<'2019-04-07T23:59:59Z' and log.runnerid=runners.runnerid and sex=0 group by log.runnerid order by d desc limit 5;
-- самая длинная пробежка
select runnername,date,distance,log.runnerid from log,runners where date>'2019-04-01T00:00:00Z' and date<'2019-04-07T23:59:59Z' and log.runnerid=runners.runnerid order by distance desc limit 5; 
select runnername,date,distance,log.runnerid from log,runners where date>'2019-04-01T00:00:00Z' and date<'2019-04-07T23:59:59Z' and log.runnerid=runners.runnerid and sex=0 order by distance desc limit 5; 
-- самая быстрая пробежка
select runnername,date,time/distance s,log.runnerid from log,runners where date>'2019-04-01T00:00:00Z' and date<'2019-04-07T23:59:59Z' and log.runnerid=runners.runnerid order by s limit 5;
select runnername,date,time/distance s,log.runnerid from log,runners where date>'2019-04-01T00:00:00Z' and date<'2019-04-07T23:59:59Z' and log.runnerid=runners.runnerid and sex=0 order by s limit 5;
