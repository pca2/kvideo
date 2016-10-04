#! /usr/bin/env ruby
require 'rss'
require 'open-uri'
require 'sequel'
require 'logger'

#DB setup
DIR = File.expand_path(File.dirname(__FILE__)) #path to containing folder
DB_PATH ="#{DIR}/kottke.db"
DB = Sequel.sqlite(DB_PATH)

class Log
  def self.log
    unless @logger
      @logger = Logger.new('topmemeo.log', 'monthly')
      @logger.level = Logger::INFO
      @logger.datetime_format = '%Y-%m-%d %H:%M:%S'
    end
    @logger
  end
end


#Define table if new db 
#TODO save finished tweet to DB
unless File.exist?(DB_PATH)
  DB.create_table :posts do 
    primary_key :id
    String :headline
    String :youtube_id, :null => false
    String :post_url, :null => false
    DateTime :post_date, :null => false
    DateTime :created_at, :null => false
  end
  Log.log.debug "DB file not found. New DB file created"
else
  Log.log.debug "DB file detected"
end

class Post < Sequel::Model
  plugin :validation_helpers
  plugin :timestamps
  def validate
    super
    validates_presence [:youtube_id, :post_url, :post_date]
    validates_format /\Ahttps?:\/\/.*\./, :post_url, :message=>'is not a valid URL'
    validates_unique :youtube_id
  end
end


url = 'http://feeds.kottke.org/main'

feed = RSS::Parser.parse(open(url))

def get_latest_post()
  #Grab the timestamp of the most recent DB entry
end

#NOTE: At the moment we're just grabbing the link. Should probably think about storing them in DB and what info you want for that
# vid_id, date, headline? 

def get_links(feed)
  feed.entries.each do |post| 
    post_date = post.updated.content
    #Test this if clause. just a stub
    if post_date == latest_post
      puts "no new videos"
      break
    end

    if post.content.content[/="http(s|):\/\/www.youtube.com.*?\"/].nil?
      puts "not a video post"
      next
    end
    links = post.content.content.scan(/youtube.*?\"/)
  end
end


def get_ids(array)
  ids = array.map{ |l| l.scan(/(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/ ]{11})/)}
  return ids.flatten
end

def get_db_ids()
  #grab an array of all the known IDs in the DB. Later we'll check against this before we insert a new one. to prevent duplicates
end

def check_dupls()

end

def add_to_db()

end

def authorize()
  # setup acct
end

def define_playlist()

end

def append_to_playlist(playlist, vid_id)
  #you'll want to merge this code and the yt code
  # and you'll be working with arrrays actually
  # check for success/catch errors
end

def reorder(playlist, vid_id)
  # set position 0. Check notes for details
  # check for success
end


links = get_links(feed)
ids = get_ids(links)


