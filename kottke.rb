#! /usr/bin/env ruby
require 'rss'
require 'open-uri'
require 'sequel'
require 'logger'

#DB setup
DIR = File.expand_path(File.dirname(__FILE__)) #path to containing folder
DB_PATH ="#{DIR}/kottke.db"
DB = Sequel.sqlite(DB_PATH)
Sequel.default_timezone= :utc

class Log
  def self.log
    unless @logger
      #@logger = Logger.new('topmemeo.log', 'monthly')
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::DEBUG
      @logger.datetime_format = '%Y-%m-%d %H:%M:%S'
    end
    @logger
  end
end


#Define table if new db 
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
    validates_unique :post_url
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
  many_to_one :post
end

########################END OF PREAMBLE##############




url = 'http://feeds.kottke.org/main'
#1. We get a feed
def get_feed(url)
  source = open(url)
  feed = RSS::Parser.parse(source)
end


def get_latest_post()
  if Post.empty?
    nil
  else
    Post.select_order_map(:post_date).last
  end
end

#Check the feed to see if the latest update is greater than the latest vid we have
def update_found(feed, latest_db_post)
  if latest_db_post.nil?
    Log.log.debug "Latest Post date is nil, table is empty. Performing initial update"
    return true
  end
  last_blog_update = feed.updated.content
  Log.log.debug "last_blog_update: #{last_blog_update}"
  Log.log.debug "latest_db_post: #{latest_db_post}" 
  if last_blog_update > latest_db_post
    Log.log.debug "Updates Detected"
    return true
  else
    Log.log.debug "No updates found"
    return false
  end
end

#Given the text content of a post, collect all of the YT links into an array
def get_links(post)
  post_links = post.content.content.scan(/youtube.*?\"/)
end

#Given an array of YT links, return an array of YT IDs
def get_ids(array)
  ids = array.map{ |l| l.scan(/(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/ ]{11})/)}
  return ids.flatten
end

def build_post(entry)
  post = Post.new
  post.headline = entry.title.content 
  Log.log.debug "headline saved"
  post.post_url = entry.link.href
  Log.log.debug "post_url saved"
  post.post_date = entry.updated.content
  Log.log.debug "post_date saved"
  Log.log.debug "Post created"
  return post
end

def build_video(vid_id,post_id)
  video = Video.new
  video.post_id = post_id
  video.youtube_id = vid_id
  Log.log.debug "Video created"
  return video
end

def save_to_db(item)
  item_class = item.class.to_s
  if item.valid?
    item.save
    Log.log.debug "#{item_class} item saved to DB"
    return item
  else
    item.errors.each {|x| Log.log.info x.join(" ")}
    Log.log.info "Not saving #{item_class} item to DB"
    return false
  end
end


def process_feed(feed,latest_db_post)
    feed.entries.each do |entry|
    Log.log.debug "Processing entry: " + entry.title.content 
    #check_date, if there's a latest_db_post to check against
    if latest_db_post && entry.updated.content <= latest_db_post
      Log.log.info "Already parsed post discovered, ending"
      exit
    end
    #. get links from post
    entry_links = get_links(entry)
    #3.  skip if post does not contain links
    if entry_links.empty?
      Log.log.info "Entry contains no links, skipping"
      next
    end
    #4. Create post obj, save to DB
    post = build_post(entry)
    saved_post = save_to_db(post)
    unless saved_post
      Log.log.info "Error saving post, moving on to next one"
      next
    end
    #7. get ID from each link
    entry_ids = get_ids(entry_links)
    #8. build VIDEO object for each ID, including a post_id
    entry_ids.each do |vid_id|
      video = build_video(vid_id,saved_post.id)
      saved_video = save_to_db(video)
    end
  end
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

#RUNTIME

if __FILE__ == $0
  #1. get feed
  feed = get_feed(url)
  #Get latest post date
  latest_db_post = get_latest_post()
  #2. Check for update
  unless update_found(feed, latest_db_post)
    Log.log.info "No updates found, exiting script"
    exit
  end
  # 2.We loop through each feed item
  process_feed(feed,latest_db_post)
  #9. save each video to DB, if it succeeds, append to playlist
  #10. reorder playlist
  #11. move on 
  #12. At the end, do some kind of unique check against playlist vids

end


