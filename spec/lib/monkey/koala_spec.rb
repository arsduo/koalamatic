require 'spec_helper'
require 'koala'
require 'monkey/koala'

describe "Koala patches" do
  describe ".with_default_middleware" do
    it "restores the middleware" do
      middleware = stub("middleware")
      Koala.http_service.faraday_middleware = middleware
      Koala.with_default_middleware {
        # stuff
      }
      Koala.http_service.faraday_middleware.should == middleware
    end

    it "executes the code in the block with the default middleware" do
      middleware = stub("middleware")
      Koala.http_service.faraday_middleware = middleware
      Koala.with_default_middleware {
        Koala.http_service.faraday_middleware.should be_nil # so Koala uses the defaults
      }
    end
  end

  describe KoalaTest do
    it "makes test_user_api accessible" do
      KoalaTest.should respond_to(:test_user_api)
    end

    it "makes live_testing_user accessible" do
      KoalaTest.should respond_to(:live_testing_user)
    end

    it "makes live_testing_friend accessible" do
      KoalaTest.should respond_to(:live_testing_friend)
    end
  end
end