#! /usr/bin/env ruby
require 'rss'
require 'open-uri'
require 'sequel'
require 'logger'
require 'yt'

CLIENT_ID = ENV["CLIENT_ID"] 
CLIENT_SECRET = ENV["CLIENT_SECRET"] 
REFRESH_TOKEN = ENV["REFRESH_TOKEN"] 
PLAYLIST_ID = ENV["PLAYLIST_ID"] 

#DB setup
DIR = File.expand_path(File.dirname(__FILE__)) #path to containing folder
DB_PATH ||= "#{DIR}/kottke.db"
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
  source = URI.open(url, 'User-Agent' => 'Mozilla/5.0')
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
  return ids.flatten.uniq
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

 def reorder_vids_from_array(playlist)
   Log.log.info "Reordering newest videos to top of list"
   playlist.each_with_index do |item, index|
     Log.log.debug "reordering #{item} to #{index}"
     reorder_vid(item, index)  
   end
 end

def process_feed(feed,latest_db_post,playlist)
  @new_items = []
  feed.entries.each do |entry|
    Log.log.info "Processing entry: " + entry.title.content 
    #check_date, if there's a latest_db_post to check against
    if latest_db_post && entry.updated.content <= latest_db_post
      Log.log.info "Already parsed post discovered, ending"
      break
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
      Log.log.debug "Processing vid_id: #{vid_id}"
      video = build_video(vid_id,saved_post.id)
      saved_video = save_to_db(video)
      next unless saved_video
      plist_item = append_to_playlist(playlist, saved_video.youtube_id)
      @new_items.push(plist_item) if plist_item
    end
  end
end


####yt code###

def define_account(token)
  account = Yt::Account.new refresh_token: token
  Log.log.debug "Account defined"
  return account
end

def define_playlist(account,playlist_id)
  playlist = Yt::Playlist.new id: playlist_id, auth: account
  Log.log.debug "Playlist defined"
  return playlist
end

def authorize_yt(client_id,client_secret)
  Yt.configure do |config|
    config.client_id = client_id
    config.client_secret = client_secret
    config.log_level = :info
  end
  Log.log.debug "YT gem configured"
end

def append_to_playlist(playlist, youtube_id)
  begin
    new_item = playlist.add_video youtube_id
    if new_item
      Log.log.info "New video #{youtube_id} appended to playlist"
      return new_item
    else
      Log.log.info "Video ID #{youtube_id} unable to be added to playlist"
    end
  rescue Yt::Errors::Forbidden
    Log.log.info "Video ID #{youtube_id} returned forbidden"
  end
  return nil
end

def reorder_vid(item, new_position)
  # check for success
  item.update position: new_position
  Log.log.info "item #{item} reorderd to #{new_position.to_s}"
end

# get array of all vids in playlist
def get_playlist_vids(playlist)
  Log.log.debug "Returning playlist vids"
  vids = Array.new
  playlist.playlist_items.each {|item| vids << item.video_id}
  return vids
end

def get_db_vids
  db_vid_array = DB[:videos].join(:posts, :id => :post_id).reverse(:post_date).select_map(:youtube_id)
end

def reorder_any_new_vids(new_items)
  reorder_vids_from_array(new_items) if new_items.count > 0
end



#RUNTIME

if __FILE__ == $0
  authorize_yt(CLIENT_ID,CLIENT_SECRET)
  account = define_account(REFRESH_TOKEN)
  playlist = define_playlist(account,PLAYLIST_ID)
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
  process_feed(feed,latest_db_post,playlist)
  Log.log.info "Completed processing feed"
  reorder_any_new_vids(@new_items)

end
