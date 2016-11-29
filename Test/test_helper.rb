#! /usr/bin/env ruby
require 'rss'
SAMPLE_DIR = File.expand_path(File.dirname(__FILE__)) + '/sample_xml/'

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

