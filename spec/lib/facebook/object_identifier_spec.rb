require 'spec_helper'
require 'facebook/object_identifier'

describe Facebook::ObjectIdentifier do
  include Facebook

  before :each do
    @url = stub("url", :host => Faker::Lorem.words(3).join("."), :path => Faker::Lorem.words(3).join("/"))
  end

  describe "KNOWN_FACEBOOK_OPERATIONS" do
    it "has a list of known Facebook operations" do
      ObjectIdentifier::KNOWN_FACEBOOK_OPERATIONS.should be_an(Array)
    end

    it "includes the ones we know about" do
      ObjectIdentifier::KNOWN_FACEBOOK_OPERATIONS.should include("comments", "search", "oauth")
    end
  end

  describe "#identify_object" do
    it "returns the result of identify_from_path if available" do
      result = stub("result")
      ObjectIdentifier.stubs(:identify_from_path).with(@url).returns(result)
      ObjectIdentifier.stubs(:identify_from_facebook).returns(stub("wrong result"))
      ObjectIdentifier.identify_object(@url).should == result
    end

    it "returns the result of identify_from_facebook if available and if identify_from_path doesn't work" do
      result = stub("result")
      ObjectIdentifier.stubs(:identify_from_path).returns(nil)
      ObjectIdentifier.stubs(:identify_from_facebook).with(@url).returns(result)
      ObjectIdentifier.identify_object(@url).should == result
    end

    it "returns unknown if the other methods don't work" do
      ObjectIdentifier.stubs(:identify_from_path).returns(nil)
      ObjectIdentifier.stubs(:identify_from_facebook).returns(nil)
      ObjectIdentifier.identify_object(@url).should == "unknown"
    end
  end

  describe "#identify_from_path" do
    it "returns rest_api if the host is the rest server" do
      @url.stubs(:host).returns(Koala::Facebook::REST_SERVER)
      ObjectIdentifier.identify_from_path(@url).should == "rest_api"
    end

    it "returns rest_api if the host is the beta rest server" do
      @url.stubs(:host).returns(Koala::Facebook::REST_SERVER.gsub(/\.facebook/, ".beta.facebook"))
      ObjectIdentifier.identify_from_path(@url).should == "rest_api"
    end

    it "returns batch if the path is just root" do
      @url.stubs(:path).returns("/")
      ObjectIdentifier.identify_from_path(@url).should == "batch_api"
    end

    it "returns facebook_operation for a path starting with of the KNOWN_FACEBOOK_OPERATIONS" do
      ObjectIdentifier::KNOWN_FACEBOOK_OPERATIONS.each do |op|
        @url.stubs(:path).returns("/#{op}/abc/123")
        ObjectIdentifier.identify_from_path(@url).should == "facebook_operation"
      end
    end

    it "returns nil otherwise" do
      ObjectIdentifier.identify_from_path(@url).should be_nil
    end
  end

  describe "#identify_from_facebook" do
    before :each do
      @result = {}
      ObjectIdentifier.stubs(:fetch_object_info).returns(@result)
    end
    
    it "gets the object's info from Facebook" do
      object = Faker::Lorem.words(1).join
      ObjectIdentifier.expects(:get_id_from_path).with(@url.path).returns(object)
      ObjectIdentifier.expects(:fetch_object_info).with(object)
      ObjectIdentifier.identify_from_facebook(@url)
    end
    
    it "returns unknown if the Facebook result isn't a hash" do
      ObjectIdentifier.stubs(:fetch_object_info).returns(nil)
      ObjectIdentifier.identify_from_facebook(@url).should == "unknown"
    end

    it "returns user if there's a first_name" do
      @result["first_name"] = "Barbara"
      ObjectIdentifier.identify_from_facebook(@url).should == "user"
    end
      
      
    it "returns user if there's a first_name" do
      @result["first_name"] = "Barbara"
      ObjectIdentifier.identify_from_facebook(@url).should == "user"
    end

    it "returns page if there's a first_name" do
      @result["username"] = "Context"
      @result["category"] = "Page"
      ObjectIdentifier.identify_from_facebook(@url).should == "page"
    end

    it "returns image if there's an images attribute" do
      @result["images"] = []
      ObjectIdentifier.identify_from_facebook(@url).should == "image"
    end
    
    it "returns comment if there's can_remove and message" do
      @result["can_remove"] = false
      @result["message"] = "my message"
      ObjectIdentifier.identify_from_facebook(@url).should == "comment"
    end
    
    it "returns app if there's a namespace" do
      @result["namespace"] = "myapp"
      ObjectIdentifier.identify_from_facebook(@url).should == "app"
    end

    it "returns the object's type if one's available" do
      @result["type"] = Faker::Lorem.words(1).to_s
      ObjectIdentifier.identify_from_facebook(@url).should == @result["type"]
    end

    it "returns nil if nothing else matches" do      
      ObjectIdentifier.identify_from_facebook(@url).should be_nil
    end
    
    it "returns probable_facebook_operation if we get the no node specified error" do
      ObjectIdentifier.stubs(:fetch_object_info).raises(Koala::Facebook::APIError.new("message" => "No node specified"))      
      ObjectIdentifier.identify_from_facebook(@url).should == "probable_facebook_operation"
    end

    it "returns error if it's another error" do
      ObjectIdentifier.stubs(:fetch_object_info).raises(Koala::Facebook::APIError.new("message" => "CRAZY FACEB0OK FAILURE"))      
      ObjectIdentifier.identify_from_facebook(@url).should == "error"
    end
  end
  
  describe "#fetch_object_info" do
    before :each do
      @api = stub("api")
      Koala::Facebook::API.stubs(:new).returns(@api)
      @api.stubs(:get_object)

      @token = stub(:token)
      @app_id = rand(2000).to_i
      KoalaTest.stubs(:app_id).returns(@app_id)
      
      @user = {"id" => Faker::Lorem.words(2).join("_"), "access_token" => Faker::Lorem.words(2).join("|")}
      KoalaTest.stubs(:live_testing_user).returns(@user)
      @friend = {"id" => Faker::Lorem.words(2).join("_"), "access_token" => Faker::Lorem.words(2).join("|")}
      KoalaTest.stubs(:live_testing_friend).returns(@friend)

      @object = Faker::Lorem.words(1).to_s
    end

    it "uses the app access token if there's no live testing user yet" do
      # for instance, when first setting them up
      # first, mock up the test user api, which we use to get the app's access token
      test_user_api = stub("test_user_api", :api => stub("api", :access_token => @token))
      KoalaTest.stubs(:test_user_api).returns(test_user_api)

      Koala::Facebook::API.expects(:new).with(@token).returns(@api)
      KoalaTest.stubs(:live_testing_user).returns(nil)
      ObjectIdentifier.fetch_object_info(@object)
    end

    it "uses the app access token if it's an app request" do
      # for instance, when first setting them up
      # first, mock up the test user api, which we use to get the app's access token
      test_user_api = stub("test_user_api", :api => stub("api", :access_token => @token))
      KoalaTest.stubs(:test_user_api).returns(test_user_api)

      Koala::Facebook::API.expects(:new).with(@token).returns(@api)
      ObjectIdentifier.fetch_object_info(@app_id.to_s)
    end

    it "uses the secondary live user if the object matches that user's ID" do
      # for instance, when first setting them up
      # first, mock up the test user api, which we use to get the app's access token
      Koala::Facebook::API.expects(:new).with(@token).returns(@api)
      KoalaTest.live_testing_friend["access_token"] = @token
      ObjectIdentifier.fetch_object_info(@friend["id"])
    end

    it "uses the main live user if it exists and nothing else matches" do
      # for instance, when first setting them up
      # first, mock up the test user api, which we use to get the app's access token
      KoalaTest.live_testing_user["access_token"] = @token      
      Koala::Facebook::API.expects(:new).with(@token).returns(@api)
      ObjectIdentifier.fetch_object_info(@object)
    end

    it "executes the call using Koala's default middleware" do
      # we can't test this directly, since it's inside a block
      # but we can test that the block gets called, and that without the block, nothing happens
      Koala.expects(:with_default_middleware)
      # this should never happen, because we're intercepting the with_default_middleware call
      ObjectIdentifier.expects(:api_for_object).never
      ObjectIdentifier.fetch_object_info(@object)
    end
  end
  
  describe "#get_id_from_path" do
    it "returns the first object after the leading /" do
      ObjectIdentifier.get_id_from_path("/foo/bar").should == "foo"
    end

    it "returns nil for /" do
      ObjectIdentifier.get_id_from_path("/").should be_nil
    end

    it "raises an error for nil" do
      expect { ObjectIdentifier.get_id_from_path(nil) }.to raise_exception
    end
  end
end