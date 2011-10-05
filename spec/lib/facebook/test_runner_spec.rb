require 'spec_helper'
require 'facebook/test_runner'
require 'facebook/api_recorder'

describe Facebook::TestRunner do
  before :each do
    RSpec::Core::Runner.stubs(:run)
    RSpec.stubs(:configure)
    @runner = Facebook::TestRunner.new
    @runner.stubs(:require_file)
  end

  it "is a TestRunner" do
    Facebook::TestRunner.superclass.should == Koalamatic::Base::TestRunner
  end

  describe ".setup_test_environment" do
    it "sets ENV[\"LIVE\"] to true" do
      prev_env = ENV["LIVE"]
      ENV["LIVE"] = "false"
      @runner.setup_test_environment
      ENV["LIVE"].should be_true
      ENV["LIVE"] = prev_env
    end
    
    it "sets the Koala Faraday middleware option to include Koala defaults" do
      @runner.setup_test_environment
      builder = stub("Faraday builder")
      builder.stubs(:use)
      builder.expects(:use).with(Koala::MultipartRequest)
      builder.expects(:request).with(:url_encoded)
      builder.expects(:adapter).with(Faraday.default_adapter)
      Koala.http_service.faraday_middleware.call(builder)
    end
    
    it "sets the Koala Faraday middleware to use our API recorder" do
      @runner.setup_test_environment
      builder = stub("Faraday builder")
      builder.stubs(:use)
      builder.expects(:use).with(Koalamatic::Base::ApiRecorder)
      builder.stubs(:request)
      builder.stubs(:adapter)
      Koala.http_service.faraday_middleware.call(builder)
    end
  end

  describe ".get_tests" do
    it "adds Koala's spec directory to the load path" do
      # this is a little less exact than I'd like, but it beats writing expectations against some very specific Bundler code
      @runner.get_tests
      $:.find {|p| p.match(/koala.*\/spec/) && !p.match(/koalamatic\/spec/)}.should
    end

    it "doesn't add the path twice" do
      found = 0
      @runner.get_tests
      @runner.get_tests
      $:.each {|p| found += 1 if p.match(/koala.*\/spec/) && !p.match(/koalamatic\/spec/)}
      found.should == 1
    end

    it "returns all the files" do
      tests = [:a, :b]
      # get the load path for this machine
      @runner.get_tests
      path = $:.find {|p| p.match(/koala.*\/spec/) && !p.match(/koalamatic\/spec/)}
      Dir.stubs(:glob).with(File.join(path, Facebook::TestRunner::SPEC_PATTERN)).returns(tests)
      results = @runner.get_tests
      results.should == tests
    end
    
    it "loads the Koala spec_helper" do
      @runner.get_tests
      path = $:.find {|p| p.match(/koala.*\/spec/) && !p.match(/koalamatic\/spec/)}
      @runner.expects(:require_file).with(File.join(path, "spec_helper.rb"))
      @runner.get_tests
    end
  end
end