require 'webrick'
require 'net/http'
require 'uri'
require './credentials.rb'

server = WEBrick::HTTPServer.new(:Port => 28537, :BindAddress => "127.0.0.1")
#                             :SSLEnable => false,
#                             :DocumentRoot => '/var/www/myapp',
#                             :ServerAlias => 'myapp.example.com')


server.mount_proc '/' do |req, res|
  code = req.query['code']
  res.body = "code=#{code}"
  uri = URI.parse("https://www.strava.com")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Post.new("/oauth/token?client_id=#{CLIENT_ID}&client_secret=#{CLIENT_SECRET}&code=#{code}&grant_type=authorization_code")
  p request.path
  p request.uri
  unless code==""
      response = http.request(request)
      puts response.body
  end
end

trap 'INT' do server.shutdown end

server.start
