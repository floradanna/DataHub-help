require 'test_helper'

class HomeControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper
  include HomeHelper

  test "test should be accessible to seek even if not logged in" do
    get :index
    assert_response :success
  end

  test "test title" do
    login_as(:quentin)
    get :index
    assert_select "title",:text=>/The Sysmo SEEK.*/, :count=>1
  end

  test "correct response to unknown action" do
    login_as(:quentin)
    assert_raises ActionController::UnknownAction do
      get :sdjgsdfjg
    end
  end

  test "should get feedback form" do
    login_as(:quentin)
    get :feedback
    assert_response :success
  end  

  test "admin link not visible to non admin" do
    login_as(:aaron)
    get :index
    assert_response :success
    assert_select "a#adminmode[href=?]",admin_path,:count=>0
  end

  test "admin tab visible to admin" do
    login_as(:quentin)
    get :index
    assert_response :success
    assert_select "a#adminmode[href=?]",admin_path,:count=>1
  end

  test "SOP tab should be capitalized" do
    login_as(:quentin)
    get :index
    assert_select "ul.tabnav>li>a[href=?]","/sops",:text=>"SOPs",:count=>1
  end

  test "SOP upload option should be capitlized" do
    login_as(:quentin)
    get :index
    assert_select "select#new_resource_type",:count=>1 do
      assert_select "option[value=?]","sop",:text=>"SOP"
    end
  end

  test "hidden items do not appear in recent items" do
    model = Factory :model, :policy => Factory(:private_policy), :title => "A title"

    login_as(:quentin)
    get :index

    #difficult to use assert_select, because of the way the tabbernav tabs are constructed with javascript onLoad
    assert !@response.body.include?(model.title)
  end

  test 'root should route to sign_up when no user, otherwise to home' do
    User.find(:all).each do |u|
      u.delete
    end
    get :index
    assert_redirected_to :controller => 'users', :action => 'new'

    Factory(:user)
    get :index
    assert_response :success
  end

  test 'should hide the forum tab for unlogin user' do
    logout
    get :index
    assert_response :success
    assert_select 'a',:text=>/Forum/,:count=>0

    login_as(:quentin)
    get :index
    assert_response :success
    assert_select 'a',:text=>/Forum/,:count=>1
  end

  test "should display home description" do
    Seek::Config.home_description="Blah blah blah - http://www.google.com"
    logout

    get :index
    assert_response :success

    assert_select "div.top_home_panel", :text=>/Blah blah blah/, :count=>1
    assert_select "div.top_home_panel a[href=?]", "http://www.google.com", :count=>1

  end

  test "should turn on/off project news and community news" do
    #turn on
    Seek::Config.project_news_enabled=true
    Seek::Config.community_news_enabled=true

    get :index
    assert_response :success

    assert_select "div.heading", :text=>/Community News/, :count=>1
    assert_select "div.heading", :text=>"#{Seek::Config.project_name} News", :count=>1

    #turn off
    Seek::Config.project_news_enabled=false
    Seek::Config.community_news_enabled=false


    get :index
    assert_response :success

    assert_select "div[class='yui-u first home_panel'][style='display:none']", :count => 1
    assert_select "div[class='yui-u home_panel'][style='display:none']", :count => 1
  end

  test "should display the link 'Recent changes in your project and across SysMo' only for SysMO project members" do
    login_as(:aaron)
    get :index
    assert_response :success

    assert_select "h2",:text => "Recent changes in your project and across #{Seek::Config.project_name}", :count => 1

    logout
    get :index
    assert_response :success

    assert_select "h2", :text => "Recent changes in your project and across #{Seek::Config.project_name}", :count => 0

    login_as(:registered_user_with_no_projects)
    get :index
    assert_response :success

    assert_select "h2", :text => "Recent changes in your project and across #{Seek::Config.project_name}", :count => 0
  end

  test "should show the content of 4 boxes" do
    #project news
    Seek::Config.project_news_enabled=true
    Seek::Config.project_news_feed_urls = "http://sbml.org/index.php?title=News&action=feed"
    Seek::Config.project_news_number_of_feed_entry = "5"

    #community news
    Seek::Config.community_news_enabled=true
    Seek::Config.community_news_feed_urls = "http://www2.warwick.ac.uk/sitebuilder2/api/rss/news.rss?page=/fac/sci/systemsbiology/publications/&rss=true, http://feeds.bbci.co.uk/news/uk/rss.xml"
    Seek::Config.community_news_number_of_feed_entry = "4,3"

    #recently viewed
    recently_viewed_items =  recently_viewed_items(1.year.ago, 10)
    #recently downloaded
    recently_downloaded_items =  recently_downloaded_items(1.year.ago, 10)

    login_as(:aaron)
    get :index
    assert_response :success

    assert_select 'div.project_news ul>li', 5
    assert_select 'div.community_news ul>li', 7
    assert_select 'div.recently_viewed ul>li', recently_viewed_items.count
    assert_select 'div.recently_downloaded ul>li', recently_downloaded_items.count

    logout
    get :index
    assert_response :success

    assert_select 'div.project_news ul>li', 5
    assert_select 'div.community_news ul>li', 7
    assert_select 'div.recently_viewed ul>li', recently_viewed_items.count
    assert_select 'div.recently_downloaded ul>li', recently_downloaded_items.count
  end
  
end
