#! /usr/bin/env ruby
require 'rss'
require 'open-uri'

url = 'http://feeds.kottke.org/main'

feed = RSS::Parser.parse(open(url))
#file = (File.readlines('main')).join(" ")
#feed = RSS::Parser.parse(file)

links = []
feed.entries.each_with_index do |post, i| 
  #Probably want to check for non-https
  if post.content.content[/="https:\/\/www.youtube.com.*?\"/].nil?
   puts "not a video post"
   next
  end
  links = post.content.content.scan(/youtube.*?\"/)
  links.map {|l| l.gsub!(/\?rel.*|\"/,"")}
  #Next: Parse the ID?
  #Store in a DB?
  binding.pry if defined? Pry
 #links << yt
 #puts links
 puts  "#{post.title.content} link: " + links.join(" ")
 #yt_id = yt[/embed\/.*\?/].gsub(/embed\/|\?/, "")
 #puts "the link for this video is https://www.youtube.com/watch?v=#{yt_id}"

end

#feed.entries.each {|x| puts x.content.content}
#feed.entries.each {|x| puts x.updated.content}
