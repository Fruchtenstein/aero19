require 'csv'
require 'sqlite3'
require 'httpclient'
require 'nokogiri'

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

#if ARGV.length < 1
#    puts 'Two few arguments'
#    exit
#end
#uid = ARGV[0]

$stdout.sync = true
conn = HTTPClient.new
token = auth
puts "-------- First token: #{token}"
db = SQLite3::Database.new("aerobia.db")
dball = SQLite3::Database.new("2018full.db")
runners = []
db.execute("select * from runners") do |r|
    rid, rname, tid, goal, isill = r
    d, t = [0, 0]
    ("01".."12").each do |m|
        puts ">>>>> #{m}"
        url = "http://aerobia.ru/api/users/#{rid}/calendar/2018/#{m}"
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
                puts "token error"
                raise 'token_error'
            end
        rescue
            puts 'retry:', $!, $@
            sleep 1
            token = auth
            puts "-------- New token: #{token}"
            retry if (retries += 1) < 3
        end
        File.open('calendar.xml', 'a') {|f| f.write(resp.content) }
        runs = x.xpath("//r")
        runs.each do |r|
            url = "http://aerobia.ru/api/users/#{rid}/workouts/#{r['id']}"
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
                    puts "token error"
                    raise 'token_error'
                end
            rescue
                puts 'retry:', $!, $@
                sleep 1
                token = auth
                puts "-------- New token: #{token}"
                retry if (retries += 1) < 3
            end
            File.open('workouts.xml', 'a') {|f| f.write(resp.content) }
            w = x.xpath("//workout")[0]
            p = x.xpath("//post")[0]
            u = x.xpath("//user")[0]
            l = p['likes_count']
            c = p['comments_count']
            ph = p['photos_count']
            puts("INSERT OR REPLACE INTO fulllog VALUES(#{u.attr('id')}, #{w.attr('id')}, \"#{w.attr('url')}\", \"#{w.attr('sport')}\", \"#{w.attr('start_at')}\", #{w.attr('distance').to_f}, #{w.attr('total_time_in_seconds').to_f}, #{w.attr('average_heart_rate').to_i}, #{w.attr('maximum_heart_rate').to_i}, #{w.attr('max_speed').to_f}, #{w.attr('max_pace').to_f}, #{w.attr('average_speed').to_f}, #{w.attr('average_pace').to_f}, #{w.attr('altitude_min').to_f}, #{w.attr('altitude_max').to_f}, #{w.attr('elevation_ascent').to_f}, #{w.attr('elevation_descent').to_f}, \"#{u.attr('gender')}\", #{l}, #{c}, #{ph})")
            dball.execute("INSERT OR REPLACE INTO fulllog VALUES(#{u.attr('id')}, #{w.attr('id')}, \"#{w.attr('url')}\", \"#{w.attr('sport')}\", \"#{w.attr('start_at')}\", #{w.attr('distance').to_f}, #{w.attr('total_time_in_seconds').to_f}, #{w.attr('average_heart_rate').to_i}, #{w.attr('maximum_heart_rate').to_i}, #{w.attr('max_speed').to_f}, #{w.attr('max_pace').to_f}, #{w.attr('average_speed').to_f}, #{w.attr('average_pace').to_f}, #{w.attr('altitude_min').to_f}, #{w.attr('altitude_max').to_f}, #{w.attr('elevation_ascent').to_f}, #{w.attr('elevation_descent').to_f}, \"#{u.attr('gender')}\", #{l}, #{c}, #{ph})")

            #sleep 1


            if ['Бег', 'Спортивное ориентирование', 'Беговая дорожка'].include? r["sport"]
                puts r
                d += w.attr('distance').to_f
                t += w.attr('total_time_in_seconds').to_f
            end
        end
        #sleep 1
    end
    if d != 0
        speed=(t/d).divmod(60)
    else
        speed=0
    end
    puts "#{r[1]}, #{r[2]}, Объемы в 2018: #{d} План: #{r[3]} Время: #{t}сек Скорость: #{speed[0]}:#{'%.4f' % speed[1]} мин/км"
    runners << [rname, d, r[3], speed[0], speed[1]]
end
puts "Имя\t\tПлан\tОбъем2018\tСр.скорость в 2018"
runners.each {|r| puts "#{r[0]}\t\t#{r[2]}\t#{'%.2f' % r[1]}\t#{r[3]}:#{'%.2f' % r[4]}"}


