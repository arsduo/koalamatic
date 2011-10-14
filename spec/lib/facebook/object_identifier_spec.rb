require 'spec_helper'
require 'facebook/object_identifier'

describe Facebook::ObjectIdentifier do
  include Facebook

  before :each do
    path_components = Faker::Lorem.words(3)
    @object = path_components.first
    @url = stub("url", :host => Faker::Lorem.words(3).join("."), :path => path_components.join("/"))
    @url.stubs(:is_a?).with(Addressable::URI).returns(true)
    @identifier = ObjectIdentifier.new(@url)
  end

  describe "KNOWN_FACEBOOK_OPERATIONS" do
    it "has a list of known Facebook operations" do
      ObjectIdentifier::KNOWN_FACEBOOK_OPERATIONS.should be_an(Array)
    end

    it "includes the ones we know about" do
      ObjectIdentifier::KNOWN_FACEBOOK_OPERATIONS.should include("comments", "search", "oauth")
    end
  end
  
  # class methods
  describe "#identify_object" do
    before :each do
      @identifier.stubs(:identify)
      ObjectIdentifier.stubs(:new).returns(@identifier)
    end
    
    it "creates a new ObjectIdentifier with the URL" do
      ObjectIdentifier.expects(:new).with(@url).returns(@identifier)
      ObjectIdentifier.identify_object(@url)
    end
    
    it "calls identify on the new ObjectIdentifier" do
      @identifier.expects(:identify)
      ObjectIdentifier.identify_object(@url)
    end
    
    it "calls identify on the new ObjectIdentifier" do
      result = stub("result 0")
      @identifier.stubs(:identify).returns(result)
      ObjectIdentifier.identify_object(@url).should == result
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
  
  # instance methods
  
  shared_examples_for "an ObjectIdentifier instance" do
    describe ".identify" do
      it "returns the result of identify_from_path if available" do
        result = stub("result 1")
        @identifier.stubs(:identify_from_path).returns(result)
        @identifier.stubs(:identify_from_facebook).returns(stub("wrong result"))
        @identifier.identify.should == result
      end

      it "returns the result of identify_from_facebook if available and if identify_from_path doesn't work" do
        result = stub("result 2")
        @identifier.stubs(:identify_from_path).returns(nil)
        @identifier.stubs(:identify_from_facebook).returns(result)
        @identifier.identify.should == result
      end

      it "returns unknown if the other methods don't work" do
        @identifier.stubs(:identify_from_path).returns(nil)
        @identifier.stubs(:identify_from_facebook).returns(nil)
        @identifier.identify.should == "unknown"
      end
      
      it "caches the objects identified" do
        result3 = stub("result 3")
        @identifier.stubs(:identify_from_path).once.returns(result3)
        @identifier.identify
        @identifier.identify.should == result3
      end
    end

    describe ".identify_from_facebook" do
      before :each do
        @result = {}
        @identifier.stubs(:fetch_object_info).returns(@result)
      end

      it "gets the object's info from Facebook" do
        @identifier.expects(:fetch_object_info)
        @identifier.identify_from_facebook
      end

      it "returns unknown if the Facebook result isn't a hash" do
        @identifier.stubs(:fetch_object_info).returns(nil)
        @identifier.identify_from_facebook.should == "unknown"
      end

      it "returns user if there's a first_name" do
        @result["first_name"] = "Barbara"
        @identifier.identify_from_facebook.should == "user"
      end

      it "returns user if there's a first_name" do
        @result["first_name"] = "Barbara"
        @identifier.identify_from_facebook.should == "user"
      end

      it "returns page if there's a first_name" do
        @result["username"] = "Context"
        @result["category"] = "Page"
        @identifier.identify_from_facebook.should == "page"
      end

      it "returns image if there's an images attribute" do
        @result["images"] = []
        @identifier.identify_from_facebook.should == "image"
      end

      it "returns comment if there's can_remove and message" do
        @result["can_remove"] = false
        @result["message"] = "my message"
        @identifier.identify_from_facebook.should == "comment"
      end

      it "returns app if there's a namespace" do
        @result["namespace"] = "myapp"
        @identifier.identify_from_facebook.should == "app"
      end

      it "returns the object's type if one's available" do
        @result["type"] = Faker::Lorem.words(1).to_s
        @identifier.identify_from_facebook.should == @result["type"]
      end

      it "returns nil if nothing else matches" do      
        @identifier.identify_from_facebook.should be_nil
      end

      it "returns probable_facebook_operation if we get the no node specified error" do
        @identifier.stubs(:fetch_object_info).raises(Koala::Facebook::APIError.new("message" => "No node specified"))      
        @identifier.identify_from_facebook.should == "probable_facebook_operation"
      end

      it "returns error if it's another error" do
        @identifier.stubs(:fetch_object_info).raises(Koala::Facebook::APIError.new("message" => "CRAZY FACEB0OK FAILURE"))      
        @identifier.identify_from_facebook.should == "error"
      end
    end

    describe ".fetch_object_info" do
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
      end

      it "uses the app access token if there's no live testing user yet" do
        # for instance, when first setting them up
        # first, mock up the test user api, which we use to get the app's access token
        test_user_api = stub("test_user_api", :api => stub("api", :access_token => @token))
        KoalaTest.stubs(:test_user_api).returns(test_user_api)

        Koala::Facebook::API.expects(:new).with(@token).returns(@api)
        KoalaTest.stubs(:live_testing_user).returns(nil)
        @identifier.fetch_object_info
      end

      it "uses the app access token if it's an app request" do
        # for instance, when first setting them up
        # first, mock up the test user api, which we use to get the app's access token
        test_user_api = stub("test_user_api", :api => stub("api", :access_token => @token))
        KoalaTest.stubs(:test_user_api).returns(test_user_api)

        Koala::Facebook::API.expects(:new).with(@token).returns(@api)
        ObjectIdentifier.new(@app_id.to_s).fetch_object_info
      end

      it "uses the secondary live user if the object matches that user's ID" do
        # for instance, when first setting them up
        # first, mock up the test user api, which we use to get the app's access token
        Koala::Facebook::API.expects(:new).with(@token).returns(@api)
        KoalaTest.live_testing_friend["access_token"] = @token
        ObjectIdentifier.new(@friend["id"]).fetch_object_info
      end

      it "uses the main live user if it exists and nothing else matches" do
        # for instance, when first setting them up
        # first, mock up the test user api, which we use to get the app's access token
        KoalaTest.live_testing_user["access_token"] = @token      
        Koala::Facebook::API.expects(:new).with(@token).returns(@api)
        @identifier.fetch_object_info
      end

      it "executes the call using Koala's default middleware" do
        # we can't test this directly, since it's inside a block
        # but we can test that the block gets called, and that without the block, nothing happens
        Koala.expects(:with_default_middleware)
        # this should never happen, because we're intercepting the with_default_middleware call
        @identifier.expects(:api_for_object).never
        @identifier.fetch_object_info
      end
    end
  end

  describe "when initialized with an Adressable::URI" do  
    describe ".new" do
      it "identifies the object from the path" do
        ObjectIdentifier.expects(:get_id_from_path).with(@url.path)
        ObjectIdentifier.new(@url)
      end
      
      it "makes the identified object available as .object" do
        object = stub("identified object")
        ObjectIdentifier.stubs(:get_id_from_path).returns(object)
        ObjectIdentifier.new(@url).object == object
      end

      it "stores the url as url" do
        ObjectIdentifier.new(@url).url.should == @url        
      end      
    end
    
    describe ".identify_from_path" do      
      it "returns rest_api if the host is the rest server" do
        @url.stubs(:host).returns(Koala::Facebook::REST_SERVER)
        @identifier.identify_from_path.should == "rest_api"
      end

      it "returns rest_api if the host is the beta rest server" do
        @url.stubs(:host).returns(Koala::Facebook::REST_SERVER.gsub(/\.facebook/, ".beta.facebook"))
        @identifier.identify_from_path.should == "rest_api"
      end

      it "returns batch if the path is just root" do
        @url.stubs(:path).returns("/")
        @identifier.identify_from_path.should == "batch_api"
      end

      it "returns facebook_operation for a path starting with of the KNOWN_FACEBOOK_OPERATIONS" do
        ObjectIdentifier::KNOWN_FACEBOOK_OPERATIONS.each do |op|
          @url.stubs(:path).returns("/#{op}/abc/123")
          ObjectIdentifier.new(@url).identify_from_path.should == "facebook_operation"
        end
      end

      it "returns nil otherwise" do
        @identifier.identify_from_path.should be_nil
      end
    end
    
    it_should_behave_like "an ObjectIdentifier instance"
  end
  
  describe "when initialized with an object" do
    before :each do
      @identifier = ObjectIdentifier.new(@object)
    end
    
    describe ".new" do
      it "makes the object available as .object" do
        @identifier.object.should == @object
      end
      
      it "leaves .url blank" do
        @identifier.url.should be_nil
      end      
    end

    describe ".identify_from_path" do      
      it "returns nil because there's no path" do
        @identifier.identify_from_path.should be_nil        
      end
    end      
    
    it_should_behave_like "an ObjectIdentifier instance"    
  end
end