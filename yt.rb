#!/usr/bin/env ruby

require 'yt'
require_relative 'credentials.rb'

Yt.configure do |config|
  config.client_id = CLIENT_ID
  config.client_secret = CLIENT_SECRET
  #config.api_key = API_KEY
end

account = Yt::Account.new refresh_token: REFRESH_TOKEN

playlist = Yt::Playlist.new id: PLAYLIST_ID, auth: account

def get_playlist_vids(playlist)
  vids = Array.new
  playlist.playlist_items.each {|item| vids << item.video_id}
  return vids
end




