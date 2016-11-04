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
    String :post_url, :null => false
    DateTime :post_date, :null => false
    DateTime :created_at, :null => false
  end
  DB.create_table :videos do
    primary_key :id
    foreign_key :post_id, :posts
    String :youtube_id, :null => false
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
    validates_presence [:post_url, :post_date]
    validates_format /\Ahttps?:\/\/.*\./, :post_url, :message=>'is not a valid URL'
  end
  one_to_many :videos
end

class Video < Sequel::Model
  plugin :validation_helpers
  plugin :timestamps
  def validate
    super
    validates_presence :youtube_id
    validates_unique :youtube_id
  end
  many_to_one :posts
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
  post = Post.new

  

end

def process_feed(feed)
    
  feed.entries do |entry|

  #check_date
  if entry.updated.content <= latest_vid_date
    Log.log.info "Already parsed post discovered, ending"
    exit
  end
  
  #. get links from post
  entry_links = get_links(post)
  #3.  skip if post does not contain links
  next if entry_links.empty?
  
  #4. Create post obj, save to DB
  #TODO: Should be method
  post = Post.new
  post.headline = entry.title.content 
  post.post_url = entry.link.href
  post.post_date = entry.updated.content
  if post.save
    Log.log.debug "Post saved to DB"
  # post.id is now attached to post
  else
    Log.log.error "Error saving post"
  end



  #7. get ID from each link
  entry_ids = get_ids(entry_links)
  #8. build VIDEO object for each ID, including a post_id
  #TODO. make method for looping through IDs and creating an Video obj for each one, then saving each one
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

if __FILE__ == $0
  #1. get feed
  feed = get_feed(url)
  #Get latest get_latest_vid
  get_latest_vid()
  #Check for update
  unless check_for_update(feed, latest_vid_date)
    puts "No updates found"
    exit
  end
  # 2.We loop through each feed item
  process_feed(feed)
  

  #9. save each video to DB, if it succeeds, append to playlist
  #10. reorder playlist
  #11. move on 
  #12. At the end, do some kind of unique check against playlist vids

end


