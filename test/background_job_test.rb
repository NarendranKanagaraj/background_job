require 'test_helper'

class BackgroundJobTest < ActiveSupport::TestCase
  test "truth" do
    assert_kind_of Module, BackgroundJob
  end
end
