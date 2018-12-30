#!/usr/bin/ruby -W0
require 'httpclient'
require 'nokogiri'
require 'csv'

creds = File.readlines('credentials', chomp:true)
creds[0]=creds[0].chomp
creds[1]=creds[1].chomp
c = HTTPClient.new
loginurl = "http://aerobia.ru/api/sign_in"
data = { "user[email]" => creds[0], "user[password]" => creds[1] }
resp = c.post(loginurl, data)
x = Nokogiri::XML(resp.content)
token = x.at_xpath('//authentication_token')["value"]

#puts "Номер\tИмя участника\t\t2018\tВ неделю"
#puts "================================================================"
s = []
CSV.foreach('2019.csv') do |runner|
    r = c.get("https://aerobia.ru/users/#{runner[1]}/statistics?date=2018-12-31&type=total_distance&view=year", { "authentication_token" => token })
    d = r.content.match(%r{name: \'Бег\',\n.*\n.*\n\s*data:.*\[(\d*),(\d*.\d*)})
    if d
        d18 = d[2].to_f
        puts "#{runner[1].to_s.rjust(7)}\t#{runner[2].ljust(18)}\t#{d18.round(2).to_s.rjust(10)}\t#{(7*d18/365).round(2).to_s.rjust(10)}"
#        puts "#{Time.now.getutc},#{runner[1]},#{runner[2]},#{d18.round(2)}"
        s << [runner[1], runner[2], d18 ]
    end
end 
ss = s.sort { |x,y| y[2].to_f <=> x[2].to_f }
csv = CSV.open('users.csv','w')
ss.each { |x| csv << x }
