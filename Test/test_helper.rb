#! /usr/bin/env ruby
require 'rss'
DIR = File.expand_path(File.dirname(__FILE__)) #path to containing folder
SAMPLE_DIR = DIR + '/sample_xml/'
FEED_URL = 'http://feeds.kottke.org/main'
DB_PATH = "#{DIR}/kottke_test.db"
SAMPLE_VID_ID_ONE = "VoVpDMaMeyM"
SAMPLE_VID_ID_TWO = "7gcQQnZX9cg"

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
