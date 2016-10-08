#! /usr/bin/env ruby
require 'minitest/autorun'
require_relative 'kottke.rb'

class KottkeTest < Minitest::Test
  #URL of feed
  @@url = 'http://feeds.kottke.org/main'

  #Setup fake feed to test with
  begin
    file = (File.open('./test_feed.txt')).read
    @@fake_feed = RSS::Parser.parse(file)
  end
  

  def test_get_feed
    feed = get_feed(@@url)
    assert_instance_of RSS::Atom::Feed, feed
  end

  def test_fake_feed
    assert_instance_of RSS::Atom::Feed, @@fake_feed
  end

  def test_get_links
    skip
    assert_equal ['link1','link2'], get_links(feed, latest_post_date)
  end
end
