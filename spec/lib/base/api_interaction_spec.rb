require 'spec_helper'
require 'base/api_interaction'

describe Koalamatic::Base::ApiInteraction do
  # so we don't have to write this out every time
  include Koalamatic::Base
  
  it "is an ActiveRecord::Base" do
    ApiInteraction.superclass.should == ActiveRecord::Base
  end
  
  it "belongs_to :test_run" do
    ApiInteraction.should belong_to(:test_run)
  end
  
  it "belongs_to api_call" do
    ApiInteraction.should belong_to(:api_call)
  end
  
  describe ".new" do
    before :each do
      @env = make_env(:url => {:inferred_port => 81})
      @url = @env[:url]
      
      @params = {
        :request_body => Faker::Lorem.words(10).join(" "),
        :duration => rand(200),
        :env => @env,
        :run => TestRun.make
      }
    end
    
    it "raises an error if not provided :env or :duration" do
      expect { (params = @params.dup)[:duration] = nil; ApiInteraction.new(params)}.to raise_exception(ArgumentError)
      expect { (params = @params.dup)[:env] = nil; ApiInteraction.new(params)}.to raise_exception(ArgumentError)
    end

    it "makes env available as .env" do
      ApiInteraction.new(@params).env.should == @params[:env]
    end

    it "makes original (request) body available as .original_body" do
      ApiInteraction.new(@params).original_body.should == @params[:request_body]
    end

    it "makes the env's url available as .url" do
      ApiInteraction.new(@params).url.should == @params[:env][:url]
    end
    
    it "works with requests with no request body (e.g. gets)" do
      expect { (params = @params.dup)[:request_body] = nil; ApiInteraction.new(params)}.not_to raise_exception(ArgumentError)
    end
    
    it "sets path to url.path" do
      ApiInteraction.new(@params).path.should == @url.path
    end

    it "sets ssl to true if url.inferred_port == 443" do
      @url.stubs(:inferred_port).returns(443)
      ApiInteraction.new(@params).ssl.should be_true
    end

    it "sets ssl to true if url.inferred_port == 443" do
      @url.stubs(:inferred_port).returns(81)
      ApiInteraction.new(@params).ssl.should be_false
    end

    it "sets host to url.host" do
      ApiInteraction.new(@params).host.should == @url.host
    end

    context "determining method" do
      it "sets method to env[:method] if there's no method in the request body" do
        @env[:body] = "no_http_here"
        ApiInteraction.new(@params).method.should == @env[:method]
      end

      it "sets method to the request body's method if present as method=value" do
        method = Faker::Lorem.words(1).join
        @params[:request_body] = "method=#{method}&abc=3"
        ApiInteraction.new(@params).method.should == method
      end

      it "sets method to the request body's method if present as _method=value" do
        method = Faker::Lorem.words(1).join
        @params[:request_body] = "abc=3&_method=#{method}"
        ApiInteraction.new(@params).method.should == method
      end
      
      it "sets method to the request body's method if the body is a hash with :method => value" do
        method = Faker::Lorem.words(1).join
        @params[:request_body] = {:method => method}
        ApiInteraction.new(@params).method.should == method
      end

      it "sets method to the request body's method if the body is a hash with :_method => value" do
        method = Faker::Lorem.words(1).join
        @params[:request_body] = {:_method => method}
        ApiInteraction.new(@params).method.should == method
      end

      it "sets method to the request body's method if the body is a hash with 'method' => value" do
        method = Faker::Lorem.words(1).join
        @params[:request_body] = {"method" => method}
        ApiInteraction.new(@params).method.should == method
      end

      it "sets method to the request body's method if the body is a hash with '_method' => value" do
        method = Faker::Lorem.words(1).join
        @params[:request_body] = {"_method" => method}
        ApiInteraction.new(@params).method.should == method
      end

      it "does not use the response body to determine the method" do
        method = Faker::Lorem.words(1).join
        @env[:body] = "_method=myBadMethod"
        @params[:request_body] = "abc=3&_method=#{method}"
        ApiInteraction.new(@params).method.should == method
      end
    end

    it "sets the status to the response status" do
      @env[:status] = "300"
      ApiInteraction.new(@params).response_status.should == @env[:status].to_i
    end
    
    it "sets the query_string to the request query" do
      query = Faker::Lorem.words(5).join("&")
      @url.stubs(:query).returns(query)
      ApiInteraction.new(@params).query_string.should == query
    end
    
    it "sets the request_body to the YAML-ified request body" do
      ApiInteraction.new(@params).request_body.should == @params[:request_body].to_yaml
    end

    it "sets the request_body for requests with objects" do
      @params[:request_body] = {
        :file => File.open(File.join(Rails.root, "Gemfile"))
      }
      ApiInteraction.new(@params).request_body.should == @params[:request_body].to_yaml
    end
    
    it "sets the run to the supplied run" do
      ApiInteraction.new(@params).test_run.should == @params[:run]
    end
  end
end
