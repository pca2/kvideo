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
  DB.create_table :entries do 
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

class Entry < Sequel::Model
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
#1. We get a feed
def get_feed(url)
  source = open(url)
  feed = RSS::Parser.parse(source)
end


def get_latest_vid()
  #Grab the timestamp of the most recent DB entry
end

#NOTE: At the moment we're just grabbing the link. Should probably think about storing them in DB and what info you want for that
# vid_id, date, headline? 

def check_for_update(feed, latest_vid_date)
  last_update = feed.updated.content
  Log.log.debug "last_update: #{last_update}"
  Log.log.debug "latest_vid_date: #{latest_vid_date}"
  if last_update > latest_vid_date
    Log.log.debug "No updates found"
    return true
  else
    Log.log.debug "Updates Detected"
    return false
  end


end

=begin 
This should be part of a separate method that just checks latest post date
    post_date = post.updated.content

    if post_date <= latest_post_date
      Log.log.debug "End of new videos"
      return post_links
    end
=end

# 2.We loop through each feed item
# MISSING

#3.  skip if post does not contain links
#4. Create post obj, save to DB
#5. get id of newly created obj
#6. get links from post
#7. get ID from each link
#8. build VIDEO object for each ID, including a post_id
#9. save each video to DB, if it succeeds, append to playlist
#10. reorder playlist
#11. move on 
#12. At the end, do some kind of unique check against playlist vids



def get_links(post)
   binding.pry if defined? Pry
  post_links = []
  if post.content.content[/="http(s|):\/\/www.youtube.com.*?\"/].nil?
    Log.log.debug "not a video post"
  end
  post_links = post.content.content.scan(/youtube.*?\"/)
end

def get_ids(array)
  ids = array.map{ |l| l.scan(/(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/ ]{11})/)}
  return ids.flatten
end

def build_post_objs(post)
  # this is the master method of processing a post
  post_objs = []
  post_links = get_links(post)
  if post_links.empty?
    return post_objs
  end
  post_ids = get_ids(post_links)

  #get_post_details
  #build obj for each post_id
  #build_obj(post_ids,post)
end

def build_entry(ids,post)
  entry = Post.new

  

end


#old get_links. can probably be deleted?
=begin
def get_links(feed, latest_post_date)
  Log.log.debug "Starting get_links"
  feed_links = []
  feed.entries.each do |post| 
    #get ids for post_links
    #build obj for each post_link, assemble into array of objs

    #feed_links = feed_links + post_links
    binding.pry if defined? Pry
  end
  return feed_links
end
=end


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

if __FILE__ == $0
  links = get_links(feed)
  ids = get_ids(links)
end


