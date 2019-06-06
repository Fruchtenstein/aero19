require 'sinatra'
require 'net/http'
require 'uri'
require 'json'
require 'sqlite3'
require_relative './config.rb'

enable :sessions
set :port => 28537, :bind => '127.0.0.1'

get '/' do
    if request['code'].nil?
        puts "No code"
    else
        begin
            retries ||= 0
            puts "code is #{request['code']}"
            uri = URI.parse("https://www.strava.com")
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            rq = Net::HTTP::Post.new("/oauth/token?client_id=#{CLIENT_ID}&client_secret=#{CLIENT_SECRET}&code=#{request['code']}&grant_type=authorization_code")
            response = http.request(rq)
        rescue => e
            puts 'Strava error, retry:', $!, $@
            sleep 1
            retry if (retries += 1) < 3
        end
        j = JSON.parse(response.body)
        puts "ID: #{j['athlete']['id']}; rtoken: #{j['refresh_token']}; atoken: #{j['access_token']}"
        begin
            retries ||= 0
            db = SQLite3::Database.new("2019.db")
            db.execute("UPDATE runners SET acctoken='#{j['access_token']}', reftoken='#{j['refresh_token']}' WHERE sid=#{j['athlete']['id']}")
            db.close
        rescue => e
            puts 'db error, retry:', $!, $@
            sleep 1
            retry if (retries += 1) < 3
        end
    end
    redirect 'http://aerobia.net'
end

get '/gudsqap' do
    "Hi, #{session['name']}, got gudsqap: #{request['code']}"
end

get '/aero' do
    redirect 'http://aerobia.ru'
end

