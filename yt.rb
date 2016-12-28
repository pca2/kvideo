#!/usr/bin/env ruby

require 'yt'
require_relative 'credentials.rb'

#1 authorize
Yt.configure do |config|
  config.client_id = CLIENT_ID
  config.client_secret = CLIENT_SECRET
  #config.api_key = API_KEY
end

#2 define account
account = Yt::Account.new refresh_token: REFRESH_TOKEN
#3 define playlist
playlist = Yt::Playlist.new id: PLAYLIST_ID, auth: account

#4 Add a video
new_item = playlist.add_video youtube_id

#7. Position the video in the first spot:
new_item.update position: 0

# get array of all vids in playlist
def get_playlist_vids(playlist)
  vids = Array.new
  playlist.playlist_items.each {|item| vids << item.video_id}
  return vids
end




