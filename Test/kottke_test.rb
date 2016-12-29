#! /usr/bin/env ruby
require 'minitest/autorun'
require 'minitest/pride'
require_relative '../kottke.rb'
require_relative 'test_helper.rb'

class KottkeTest < Minitest::Test
#URL of feed
@@url = 'http://feeds.kottke.org/main'

  #Setup fake feed to test with
=begin
    file = (File.open('./test_feed.txt')).read
    @@fake_feed = RSS::Parser.parse(file)
=end
  #End Setup   

  def test_get_feed
    skip
    feed = get_feed(@@url)
    assert_instance_of RSS::Atom::Feed, feed
  end

  def test_get_single_link
    post = get_sample_entry('oneembed.xml')    
    assert_equal ["youtube.com/embed/I-vAp9n8rQc?rel=0\""], get_links(post)
  end
  
  def test_get_no_vid
    post = get_sample_entry('novid.xml')
    assert_equal [], get_links(post)
  end
 
  def test_two_embed
    post = get_sample_entry('twoembed.xml')
    assert_equal ["youtube.com/embed/UVd8VGwq5w8?rel=0\"", "youtube.com/embed/KIojBBCPcqQ?rel=0\""], get_links(post)
  end
  
  def test_multiembed_multilink
    post = get_sample_entry('multi-embed_links.xml')
    assert_equal ["youtube.com/embed/37VhTWokgNU?rel=0\"", "youtube.com/embed/DLiCbVyO0F4?rel=0\"", "youtube.com/embed/yrPbt03-8lI?rel=0\"", "youtube.com/watch?v=Fs1DYdy0Qk8\"", "youtube.com/embed/ZeCYZgwQYEU?rel=0\""], get_links(post)
  end

  def test_link_only
    post = get_sample_entry('link_only.xml')
    assert_equal ["youtube.com/user/caseyneistat\"", "youtube.com/watch?v=iPPzXlMdi7o\""], get_links(post)
  end

  def test_get_ids
    assert_equal ["iPPzXlMdi7o","DLiCbVyO0F4"], get_ids(["youtube.com/user/caseyneistat\"", "youtube.com/watch?v=iPPzXlMdi7o\"","youtube.com/embed/DLiCbVyO0F4?rel=0\""])
  end

  def test_get_ids_null
    assert_equal [], get_ids([])
  end

  def test_update_found
    feed = get_sample_feed('sample.xml')
    latest_post_date = Time.utc('2016','10','07', '18', '22', '47')
    assert_equal false, update_found(feed,latest_post_date)
  end

  def test_db_file_exists
    assert_equal true, File.file?(DB_PATH), "DB file should exist"
  end

  def test_db_tables_defined
    assert_equal [:posts, :videos], DB.tables
  end

  def test_process_feed
    feed = get_sample_feed('sample.xml')
    latest_post_date = Time.utc('2015')
    truncate_tables(['videos','posts'])
    process_feed(feed, latest_post_date)
    assert_equal 9, DB[:videos].count, "Processing of sample feed should result in 9 video rows"
  end

  def test_build_post
    entry = get_sample_entry('sample.xml')
    post = build_post(entry)
    assert_equal "Lovely brand design for a Nashville conference", post.headline, "Headline of sample entry should match"
  end

  def test_save_to_db
    DB[:videos].delete
    DB[:posts].delete
    entry = get_sample_entry('sample.xml')
    post = build_post(entry)
    saved_post = save_to_db(post)
    assert_equal 1, DB[:posts].where(headline: "Lovely brand design for a Nashville conference").count
  end

  def test_build_video

  end

  def test_get_latest_post

  end


end
