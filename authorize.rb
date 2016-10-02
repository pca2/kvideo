#!/usr/bin/env ruby
# Authorization script. For details see: https://github.com/Fullscreen/yt#configuring-your-app

require 'yt'
require_relative 'credentials.rb'

Yt.configure do |config|
  config.client_id = CLIENT_ID
  config.client_secret = CLIENT_SECRET
  config.api_key = API_KEY
end
YOUTUBE_SCOPE = 'userinfo.profile,youtube'

redirect_uri = "http://sostark.net"

puts <<~END
 
  Go to the following URL below and authorize the app.
  After authorizing you will be returned to a URL with a path that looks like 'example.com/?code=4/jther...'
  The part beginging with '4' is the start of your authorization code. Write it down.

END
puts Yt::Account.new(scopes: [YOUTUBE_SCOPE], redirect_uri: redirect_uri ).authentication_url
puts ""

