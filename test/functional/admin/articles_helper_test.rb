require File.dirname(__FILE__) + '/../../test_helper'

class Admin::ArticlesHelperTest < ActionController::TestCase
  include Admin::ArticlesHelper
  
  def test_should_show_published_at_dates
    assert_equal 'not published', published_at_for(nil)
    assert_equal 'not published', published_at_for(Article.new)
  end
end
