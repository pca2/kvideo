#!/usr/bin/env ruby
# Authorization script. For details see: https://github.com/Fullscreen/yt#configuring-your-app
# This script (1 of 2) uses CLIENT_ID, CLIENT_SECRET and API_KEY to get a new authorization code
# The next script will then use authorization code to get the refresh and access tokens

require 'yt'

REDIRECT_URI = ENV["REDIRECT_URI"]
API_KEY = ENV["API_KEY"]
CLIENT_ID = ENV["CLIENT_ID"] 
CLIENT_SECRET = ENV["CLIENT_SECRET"] 

Yt.configure do |config|
  config.client_id = CLIENT_ID
  config.client_secret = CLIENT_SECRET
  config.api_key = API_KEY
end
YOUTUBE_SCOPE = ['userinfo.profile', 'youtube']


puts <<~END
  This script is part 1 of 2 of the full authorization process.
  Go to the following URL below and authorize the app.
  After authorizing you will be returned to a URL with a path that looks like 'example.com/?code=4/jther...'
  The part beginging with '4' is the start of your authorization code.
  Update the credentials.rb file with your new authorization code.
  You then must run the second script (get_refresh_code.rb) to get your refresh token and access token.
  Once you've updated the credentials file with the new refresh and access tokens the script should be fully authorized and ready to run.

END
puts Yt::Account.new(scopes: YOUTUBE_SCOPE, redirect_uri: REDIRECT_URI, force: true ).authentication_url
puts ""

