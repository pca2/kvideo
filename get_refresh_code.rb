#!/usr/bin/env ruby
# This script is part 2 of 2. Running authorize.rb beforehand is required
require 'uri'
require 'net/http'
require 'openssl'
require_relative 'credentials'
require 'cgi'

url = URI("https://accounts.google.com/o/oauth2/token")

http = Net::HTTP.new(url.host, url.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE

request = Net::HTTP::Post.new(url)
request["cache-control"] = 'no-cache'
request["content-type"] = 'application/x-www-form-urlencoded'
url_options = "code=#{CGI.escape(AUTHORIZATION_CODE)}&client_id=#{CGI.escape(CLIENT_ID)}&client_secret=#{CGI.escape(CLIENT_SECRET)}&redirect_uri=#{CGI.escape(REDIRECT_URI)}&grant_type=authorization_code"
request.body = url_options
puts <<~END
  This script is part 2 of 2. You should have already run authorize.rb and received a new authorization code.
  Below you should find your new access token and refresh token. Update the credentials file with them and you're good to go.

END

response = http.request(request)
puts response.read_body

