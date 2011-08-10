require 'test_helper'

class ApiControllerTest < ActionController::TestCase
  test "should get start_run" do
    get :start_run
    assert_response :success
  end

end
