require 'spec_helper'
require 'base/api_interaction'

describe Koalamatic::Base::ApiInteraction do
  # so we don't have to write this out every time
  include Koalamatic::Base
  
  it "is an ActiveRecord::Base" do
    ApiInteraction.superclass.should == ActiveRecord::Base
  end
  
  describe "#create_from_call" do
    before :each do
      @url = stub("url",
        :path => Faker::Lorem.words(2).join("/"),
        :host => Faker::Lorem.words(3).join("."),
        :inferred_port => 81
      )

      @env = {
        :body => Faker::Lorem.words(10).join(" "),
        :method => "get",
        :url => @url
      }
      
      @params = {
        :request_body => Faker::Lorem.words(10).join(" "),
        :duration => rand(200),
        :env => @env
      }
    end
    
    it "raises an error if not provided :env, :duration, and :request_body" do
      expect { (params = @params.dup)[:request_body] = nil; ApiInteraction.create_from_call(params)}.to raise_exception(ArgumentError)
      expect { (params = @params.dup)[:duration] = nil; ApiInteraction.create_from_call(params)}.to raise_exception(ArgumentError)
      expect { (params = @params.dup)[:env] = nil; ApiInteraction.create_from_call(params)}.to raise_exception(ArgumentError)
    end
    
    it "sets path to url.path" do
      ApiInteraction.expects(:create).with(has_entries(:path => @url.path))
      ApiInteraction.create_from_call(@params)
    end

    it "sets ssl to true if url.inferred_port == 443" do
      @url.stubs(:inferred_port).returns(443)
      ApiInteraction.expects(:create).with(has_entries(:ssl => true))
      ApiInteraction.create_from_call(@params)
    end

    it "sets ssl to true if url.inferred_port == 443" do
      @url.stubs(:inferred_port).returns(81)
      ApiInteraction.expects(:create).with(has_entries(:ssl => false))
      ApiInteraction.create_from_call(@params)
    end

    it "sets host to url.host" do
      ApiInteraction.expects(:create).with(has_entries(:host => @url.host))
      ApiInteraction.create_from_call(@params)
    end

    it "sets host to url.host" do
      ApiInteraction.expects(:create).with(has_entries(:host => @url.host))
      ApiInteraction.create_from_call(@params)
    end      

    it "sets method to env[:method] if there's no method in the request body" do
      @env[:body] = "no_http_here"
      ApiInteraction.expects(:create).with(has_entries(:method => @env[:method]))
      ApiInteraction.create_from_call(@params)
    end

    it "sets method to the request body's method if present as method=value" do
      method = Faker::Lorem.words(1).to_s
      @params[:request_body] = "method=#{method}&abc=3"
      ApiInteraction.expects(:create).with(has_entries(:method => method))
      ApiInteraction.create_from_call(@params)
    end

    it "sets method to the request body's method if present as _method=value" do
      method = Faker::Lorem.words(1).to_s
      @params[:request_body] = "abc=3&_method=#{method}"
      ApiInteraction.expects(:create).with(has_entries(:method => method))
      ApiInteraction.create_from_call(@params)
    end

    it "does not use the response body to determine the method" do
      method = Faker::Lorem.words(1).to_s
      @env[:body] = "_method=myBadMethod"
      @params[:request_body] = "abc=3&_method=#{method}"
      ApiInteraction.expects(:create).with(has_entries(:method => method))
      ApiInteraction.create_from_call(@params)
    end

    it "sets the status to the response status" do
      @env[:status] = "300"
      ApiInteraction.expects(:create).with(has_entries(:response_status => @env[:status].to_i))
      ApiInteraction.create_from_call(@params)
    end
  end
end
