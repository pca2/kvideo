#! /usr/bin/env ruby
require 'minitest/autorun'
require 'minitest/pride'
require_relative 'test_helper.rb'#must be required first for DB path
require_relative '../kottke.rb'

class KottkeTest < Minitest::Test
  def setup
    truncate_tables(['videos','posts'])
  end

  def test_get_feed
    feed = get_feed(FEED_URL)
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
  
  def test_get_ids_removes_duplicates
    assert_equal ["iPPzXlMdi7o","DLiCbVyO0F4"], get_ids(["youtube.com/watch?v=iPPzXlMdi7o\"", "youtube.com/watch?v=iPPzXlMdi7o\"","youtube.com/embed/DLiCbVyO0F4?rel=0\""])
  end

  def test_get_ids_null
    assert_equal [], get_ids([])
  end

  def test_update_found
    feed = get_sample_feed('sample.xml')
    latest_post_date = Time.utc('2016','10','07', '18', '22', '47')
    refute update_found(feed,latest_post_date)
  end

  def test_db_file_exists
    assert File.file?(DB_PATH), "DB file should exist"
  end

  def test_db_tables_defined
    assert_equal [:posts, :videos], DB.tables
  end

  def test_process_feed
    authorize_yt(CLIENT_ID,CLIENT_SECRET)
    account = define_account(REFRESH_TOKEN)
    dummy_playlist = create_dummy_playlist(account)
    feed = get_sample_feed('sample.xml')
    process_feed(feed, nil,dummy_playlist)
    reorder_any_new_vids(@new_items)
    assert_equal 8, DB[:videos].count, "Processing of sample feed should result in 9 video rows"
    delete_playlist(dummy_playlist)
  end

  def test_process_feed_with_duplicate_links
    authorize_yt(CLIENT_ID,CLIENT_SECRET)
    account = define_account(REFRESH_TOKEN)
    dummy_playlist = create_dummy_playlist(account)
    feed = get_sample_feed('same_video_twice.xml')
    process_feed(feed, nil,dummy_playlist)
    reorder_any_new_vids(@new_items)
    assert_equal 2, DB[:videos].count, "Processing of sample feed should result in 2 video rows"
    delete_playlist(dummy_playlist)
  end

  def test_build_post
    entry = get_sample_entry('sample.xml')
    post = build_post(entry)
    assert_equal "Lovely brand design for a Nashville conference", post.headline, "Headline of sample entry should match"
  end

  def test_save_to_db
    entry = get_sample_entry('sample.xml')
    post = build_post(entry)
    saved_post = save_to_db(post)
    assert_equal 1, DB[:posts].where(headline: "Lovely brand design for a Nashville conference").count
  end

  def test_build_video
    entry = get_sample_entry('sample.xml')
    post = build_post(entry)
    saved_post = save_to_db(post)
    video = build_video("iPPzXlMdi7o",saved_post.id)
    assert_equal "iPPzXlMdi7o", video.youtube_id
  end

  def test_get_latest_post_returns_nil_on_empty_DB
    assert_nil get_latest_post

  end

  def test_get_latest_post
    authorize_yt(CLIENT_ID,CLIENT_SECRET)
    account = define_account(REFRESH_TOKEN)
    dummy_playlist = create_dummy_playlist(account)
    feed = get_sample_feed('sample.xml')
    process_feed(feed, nil,dummy_playlist)
    latest_post_date = get_latest_post
    assert_equal latest_post_date, Time.utc('2016','10','07', '14', '26', '11') 
    delete_playlist(dummy_playlist)
  end

  def test_account_valid
    authorize_yt(CLIENT_ID,CLIENT_SECRET)
    account = define_account(REFRESH_TOKEN)
    assert Time.now < account.expires_at
  end

  def test_playlist_valid
    authorize_yt(CLIENT_ID,CLIENT_SECRET)
    account = define_account(REFRESH_TOKEN)
    playlist = define_playlist(account,PLAYLIST_ID)
    assert_equal playlist.id, PLAYLIST_ID
  end

  def test_append_to_playlist
    authorize_yt(CLIENT_ID,CLIENT_SECRET)
    account = define_account(REFRESH_TOKEN)
    dummy_playlist = create_dummy_playlist(account)
    new_item = append_to_playlist(dummy_playlist, SAMPLE_VID_ID_ONE)
    assert new_item.exists?
    delete_playlist(dummy_playlist)
  end

  def test_reorder_vid
    authorize_yt(CLIENT_ID,CLIENT_SECRET)
    account = define_account(REFRESH_TOKEN)
    dummy_playlist = create_dummy_playlist(account)
    feed = get_sample_feed('sample.xml')
    process_feed(feed, nil,dummy_playlist)
    reorder_any_new_vids(@new_items)
    playlist_array = get_playlist_vids(dummy_playlist)
    db_array = get_db_vids
    check_result = check_vid_arrays_match(playlist_array,db_array)
    assert check_result, "playlist and db vid arrays should be identical"
    delete_playlist(dummy_playlist)
  end

  def test_new_vids_at_top
    authorize_yt(CLIENT_ID,CLIENT_SECRET)
    account = define_account(REFRESH_TOKEN)
    dummy_playlist = create_dummy_playlist(account)
    new_item = append_to_playlist(dummy_playlist, SAMPLE_VID_ID_ONE)
    new_item = append_to_playlist(dummy_playlist, SAMPLE_VID_ID_TWO)
    feed = get_sample_feed('twoembed.xml')
    process_feed(feed, nil,dummy_playlist)
    reorder_any_new_vids(@new_items)
    playlist_array = get_playlist_vids(dummy_playlist)
    check_result = check_vid_arrays_match(playlist_array,NEW_VID_ON_TOP_LIST)
    assert check_result, "playlist and NEW_VID_ON_TOP_LIST arrays should be identical"
    delete_playlist(dummy_playlist)
  end
  
  def test_catch_forbidden_error
    authorize_yt(CLIENT_ID,CLIENT_SECRET)
    account = define_account(REFRESH_TOKEN)
    dummy_playlist = create_dummy_playlist(account)
    new_item = append_to_playlist(dummy_playlist, SAMPLE_FORBIDDEN_VID)
    assert new_item.nil?
    delete_playlist(dummy_playlist)
  end

end
