#! /usr/bin/env ruby
require 'rss'
require 'open-uri'

url = 'http://feeds.kottke.org/main'

feed = RSS::Parser.parse(open(url))


feed.entries.each do |post| 
  binding.pry if defined? Pry
  if !post.content.content.include?("tag/video")
   puts "not a video post"
   next
  end
 yt = post.content.content[/youtube.*rel=0/]
 yt_id = yt[/embed\/.*\?/].gsub(/embed\/|\?/, "")
 puts "the link for this video is https://www.youtube.com/watch?v=#{yt_id}"

end

#feed.entries.each {|x| puts x.content.content}
#feed.entries.each {|x| puts x.updated.content}
