#! /usr/bin/env ruby
require 'rss'
require 'open-uri'

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


