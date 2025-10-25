#! /usr/bin/env ruby
require 'rss'
require 'vcr'
require 'webmock/minitest'
require 'cgi'

# Set dummy environment variables for testing
# VCR will intercept all HTTP requests, so these fake values won't be used
ENV['CLIENT_ID'] ||= 'fake_client_id_for_testing'
ENV['CLIENT_SECRET'] ||= 'fake_client_secret_for_testing'
ENV['REFRESH_TOKEN'] ||= 'fake_refresh_token_for_testing'
ENV['PLAYLIST_ID'] ||= 'fake_playlist_id_for_testing'

DIR = File.expand_path(File.dirname(__FILE__)) #path to containing folder
SAMPLE_DIR = DIR + '/sample_xml/'
FEED_URL = 'http://feeds.kottke.org/main'
DB_PATH = "#{DIR}/kottke_test.db"
SAMPLE_VID_ID_ONE = "VoVpDMaMeyM"
SAMPLE_VID_ID_TWO = "7gcQQnZX9cg"
SAMPLE_FORBIDDEN_VID = "4zCFMrxDz9Y"
NEW_VID_ON_TOP_LIST = ["mxcpOrIT5PQ","KIojBBCPcqQ","VoVpDMaMeyM","7gcQQnZX9cg"]

# Configure VCR
VCR.configure do |config|
  config.cassette_library_dir = "#{DIR}/vcr_cassettes"
  config.hook_into :webmock
  config.default_cassette_options = { record: :once }

  # Filter sensitive data in requests and responses
  config.filter_sensitive_data('<YOUTUBE_CLIENT_ID>') { ENV['CLIENT_ID'] }
  config.filter_sensitive_data('<YOUTUBE_CLIENT_SECRET>') { ENV['CLIENT_SECRET'] }

  # Filter refresh token (both plain and URL-encoded forms)
  if ENV['REFRESH_TOKEN']
    config.filter_sensitive_data('<YOUTUBE_REFRESH_TOKEN>') { ENV['REFRESH_TOKEN'] }
    config.filter_sensitive_data('<YOUTUBE_REFRESH_TOKEN>') { CGI.escape(ENV['REFRESH_TOKEN']) }
  end

  # Filter playlist ID
  config.filter_sensitive_data('<YOUTUBE_PLAYLIST_ID>') { ENV['PLAYLIST_ID'] }

  # Filter access tokens from response bodies and headers
  config.before_record do |interaction|
    # Filter access_token from JSON responses
    if interaction.response.body.include?('access_token')
      interaction.response.body.gsub!(/"access_token":\s*"[^"]*"/, '"access_token": "<YOUTUBE_ACCESS_TOKEN>"')
    end

    # Filter id_token from JSON responses (JWT tokens)
    if interaction.response.body.include?('id_token')
      interaction.response.body.gsub!(/"id_token":\s*"[^"]*"/, '"id_token": "<YOUTUBE_ID_TOKEN>"')
    end

    # Filter Bearer tokens from Authorization headers
    if interaction.request.headers['Authorization']
      interaction.request.headers['Authorization'] = ['Bearer <YOUTUBE_ACCESS_TOKEN>']
    end
  end

  # Allow localhost connections for feed testing
  config.ignore_localhost = false
  config.allow_http_connections_when_no_cassette = false
end

def get_sample_feed(xml)
  file = (File.open(SAMPLE_DIR + xml)).read
  return feed = RSS::Parser.parse(file)
end

def get_sample_entry(xml)
 feed = get_sample_feed(xml)
  return feed.entries.first
end


def truncate_tables(array)
  array.each do |table|
    DB[table.to_sym].truncate
  end
end

def create_dummy_playlist(account)
  test_playlist = account.create_playlist title: "test_#{Time.now.to_i}"
end

def delete_playlist(playlist)
  playlist.delete
end

def check_vid_arrays_match(array_one,array_two)
  Log.log.info "Checking if db vids match playlist vids"
  if array_one == array_two
    Log.log.info "Arrays match"
    return true
  else
    Log.log.error "Array mismatch"
    return false
  end
end
