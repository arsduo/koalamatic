require 'spec_helper'
require 'base/analysis/matchers/matcher'
require 'base/api_call'

describe Koalamatic::Base::Analysis::Matcher do
  include Koalamatic::Base
  include Koalamatic::Base::Analysis

  after :each do
    Matcher.conditions = {}
  end

  it "has a conditions hash" do
    Matcher.conditions.should be_a(Hash)
  end

  describe ".add_condition" do
    it "complains if not passed arguments" do
      expect { Matcher.add_conditions("foo") }.to raise_exception(ArgumentError)
    end

    it "complains if not passed a hash" do
      expect { Matcher.add_conditions("foo", []) }.to raise_exception(ArgumentError)
    end

    it "tracks the condition and its params" do
      condition_name = Faker::Lorem.words(1).first
      conditions = {:url => "/foo/bar"}
      Matcher.add_condition(condition_name, condition)
      Matcher.conditions[condition_name].should == conditions
    end

    it "tracks the condition and its params" do
      condition_name = Faker::Lorem.words(1).first
      conditions = {:url => "/foo/bar"}
      new_conditions = {:foo => :baz}
      Matcher.add_condition(condition_name, condition)
      Matcher.add_condition(condition_name, new_condition)
      Matcher.conditions[condition_name].should == new_conditions
    end
  end

  describe ".method_missing" do
    before :each do
      @method = Faker::Lorem.words(1).first
    end

    context "if the method matches an ApiInteraction column" do
      before :each do
        ApiInteraction.column_names.stubs(:include?).with(@method).returns(true)
        @args = {:foo => stub("argument"), :bar => stub("arg2")}
      end

      it "defines a new class method for the desired column" do
        Matcher.should_not respond_to(@method)
        Matcher.send(@method)
        Matcher.should respond_to(@method)
      end

      describe "the new method" do
        it "is defined on the base matcher class, not any subclass" do
          class TestMatcher < Matcher; end
          TestMatcher.send(@method, @args)
          Matcher.should respond_to(@method)
        end

        it "calls add_condition with the remaining arguments" do
          Matcher.send(@method)
          Matcher.expects(:add_condition).with(@args)
          Matcher.send(@method, @args)
        end
      end

      it "calls the new method with the given arguments" do
        Matcher.expects(:add_condition).with(@args)
        Matcher.send(@method, @args)
      end
    end

    context "if the method doesn't match a column name" do
      it "follows the regular path" do
        expect { Matcher.send(@method) }.to raise_exception(NoMethodError)
      end
    end
  end

  describe ".url" do
    it "adds the results as the url condition" do
      args = ["a", "b", "c"]
      Matcher.expects(:add_condition).with(hash_including(:url => anything))
      Matcher.url(*args)
    end

    it "joins the arguments with \/, prepending ^/, as a regular expression" do
      args = ["a", "b", "c"]
      Matcher.expects(:add_condition).with(hash_including("^/" + Regexp.new(args.join("\/"))))
      Matcher.url(*args)
    end

    it "turns regular expressions into their string form" do
      regexp1 = /0-9\_/
      regexp2 = /def/
      args = [regexp1, "b", regexp2]
      expected = args.collect {|s| s.to_s}
      Matcher.expects(:add_condition).with(hash_including(Regexp.new(expected.join("\/"))))
      Matcher.url(*args)
    end

    context "url helper methods" do
      describe ".any_segments" do
        it "returns a regexp for one or more segments" do
          Matcher.any_segment.should == /.+/
        end
      end

      # will be factored into a separate Facebook matcher at some point
      describe ".facebook_id" do
        it "returns a regexp for a Facebook ID" do
          Matcher.facebook_id.should == /[A-Za-z0-9\_]+/
        end
      end

      describe ".facebook_connection" do
        it "returns a regexp for a Facebook connection" do
          Matcher.facebook_connection.should == /[a-z]+/
        end
      end
    end

    context "tested against real examples" do
      it "is pending"
    end
  end

  describe ".match?" do
    before :each do
      @interaction = ApiInteraction.make
    end

    before :each do
      Matcher.add_condition(:test1 => /foo\/bar/)
      Matcher.add_condition(:test2 => "string")
    end

    it "tests each condition against the appropriate attribute" do
      Matcher.conditions.each_pair do |attribute, test|
        Matcher.expects(:condition_matches?).with(@interaction, attribute, test).returns(true)
      end
      Matcher.match?(@interaction)
    end

    it "stops if any test returns false" do
      Matcher.stubs(:condition_matches?).with(anything, :test1, anything).returns(false)
      Matcher.expects(:condition_matches?).with(anything, :test2, anything).never
      Matcher.match?(@interaction)
    end


    it "returns false unless all conditions match" do
      Matcher.stubs(:condition_matches?).returns(true)
      Matcher.expects(:condition_matches?).with(anything, :test1, anything).returns(false)
      Matcher.match?(@interaction).should be_false
    end

    it "returns true if all conditions match" do
      Matcher.stubs(:condition_matches?).returns(true)
      Matcher.match?(@interaction).should be_false
    end
  end

  describe ".condition_matches?" do
    before :each do
      ApiInteraction.column_names.stubs(:include?).returns(true)
      @interaction = ApiInteraction.make
    end

    it "throws an ArgumentError if the condition isn't a column on ApiInteraction" do
      ApiInteraction.column_names.stubs(:include?).returns(false)
      expect { Matcher.condition_matches(@interaction, "foo", "bar") }.to raise_exception(ArgumentError)
    end

    # arguably testing implementation, but these are so basic
    # (we could also test true/false cases instead of using the stubs)
    it "returns the result of =~ if the condition is a Regexp" do
      method = "foo"
      test_result = stub("result of test")
      result = stub("attribute", :=~ => test_result)
      Matcher.condition_matches(@interaction, method, /test/).should == test_result
    end

    it "returns the result of == if the condition is a Regexp" do
      method = "foo"
      test_result = stub("result of test")
      result = stub("attribute", :== => test_result)
      Matcher.condition_matches(@interaction, method, "test").should == test_result
    end
  end

  describe ".test" do
    before :each do
      @interaction = ApiInteraction.make
    end
    
    it "tests the interaction" do
      Matcher.expects(:match?).with(@interaction)
      Matcher.test(@interaction)
    end
    
    context "if it's a match" do
      before :each do
        @record = ApiCall.make
        Matcher.expects(:find_or_create_api_call).returns(@record)
        Matcher.expects(:match?).returns(true)
      end
      
      it "finds or creates an ApiCall record" do
        Matcher.expects(:find_or_create_api_call).with(@interaction)
        Matcher.test(@interaction)
      end
      
      it "returns the found or created ApiCall" do
        Matcher.test(@interaction).should == @record
      end
      
      it "associates this ApiInteraction with the ApiCall" do
        Matcher.test(@interaction)
        @interaction.api_call.should == @record
      end
      
      it "saves the ApiInteraction record" do
        Matcher.test(@interaction)
        @interaction.api_call.should == @record
      end      
    end
    
    context "if not a match" do
      before :each do
        Matcher.stubs(:match?).returns(false)
      end
      
      it "returns nil" do
        Matcher.test(@interaction).should be_nil
      end
    end
  end

  describe ".find_or_create_api_call" do
    before :each do
      @interaction = ApiInteraction.make
    end

    it "looks for a matching record" do
      hash = {}
      # protected method, used by subclasses
      Matcher.stubs(:where_clause).returns(hash)
      ApiCall.expects(:where).with(hash)
      Matcher.find_or_create_api_call(@interaction)
    end
    
    it "returns it if found" do
      record = stub("record")
      ApiCall.expects(:where).with(hash).returns(record)
      Matcher.find_or_create_api_call(@interaction).should == record      
    end
    
    it "creates a saved new record if not" do
      # that the record created has the appropriate details will be tested in subclasses
      ApiCall.expects(:where).with(hash)
      result = Matcher.find_or_create_api_call(@interaction)
      result.should be_an(ApiCall)
      result.should_not be_a_new_record
    end
  end
end