shared_examples_for "the Matcher class and its subclasses" do

  include Koalamatic::Base 
  include Koalamatic::Base::Analysis

  after :each do
    @klass.conditions = {}
  end

  it "has a conditions hash" do
    @klass.conditions.should be_a(Hash)
  end

  describe ".add_condition" do   
    before :each do
      @condition_name = Faker::Lorem.words(1).first   
    end

    it "tracks the condition" do
      condition = "/foo/bar"
      @klass.add_condition(@condition_name, condition)
      @klass.conditions[@condition_name].should == condition
    end

    it "overwrites a condition if called again for the same name twice" do
      condition = "/foo/bar"
      new_condition = /baz|bam/
      @klass.add_condition(@condition_name, condition)
      @klass.add_condition(@condition_name, new_condition)
      @klass.conditions[@condition_name].should == new_condition
    end

    it "stores a block if no arguments are provided" do
      @klass.add_condition(@condition_name) { }
      @klass.conditions[@condition_name].should be_a(Proc)
    end

    it "ignores the block if arguments are provided" do
            @klass.add_condition(@condition_name, "foo") { }
      @klass.conditions[@condition_name].should be_a(String)
    end

    it "raises ArgumentError if no argument is provided" do
      expect { @klass.add_condition(@condition_name) }.to raise_exception(ArgumentError)
    end 
  end

  describe ".method_missing" do
    before :each do
      @method = Faker::Lorem.words(3).join("__").to_sym
    end

    context "if the method matches an ApiInteraction column" do
      before :each do
        ApiInteraction.column_names << @method.to_s # column_names are strings
        @args = {:foo => stub("argument"), :bar => stub("arg2")}
      end

      after :each do
        ApiInteraction.column_names.delete_if {|m| m == @method}        
      end

      it "defines a new class method for the desired column" do
        @klass.should_not respond_to(@method)
        @klass.send(@method, @args)
        @klass.should respond_to(@method)
      end

      describe "the new method" do
        it "is defined on the base Matcher class, not any subclass" do
          class TestMatcher < @klass; end
          TestMatcher.send(@method, @args)
          @klass.should respond_to(@method)
        end

        it "calls add_condition with the remaining arguments" do
          @klass.send(@method, @args)
          @klass.expects(:add_condition).with(@method, @args)
          @klass.send(@method, @args)
        end

        it "passes a block provided" do
          yielded = false
          # we have to split this into two parts due to how blocks get passed around
          # (e.g. Mocha's @klasss can't directly detect that a block was passed in)
          # instead, we detect first that the right regular arguments are included
          # then we execute the block that we expect to be passed
          # (we could also check if conditions[@@klass] == block...)
          #  but this way is independent of how add_condition works / whether other args are passed)
          @klass.expects(:add_condition).yields
          @klass.send(@method) { yielded = true }
          # and check if the block was indeed passed
          yielded.should be_true
        end

        it "calls add_condition with the remaining arguments" do
          @klass.send(@method, @args)
          @klass.expects(:add_condition).with(@method, @args)
          @klass.send(@method, @args)
        end
      end

      it "calls the new method after defining it" do
        @klass.expects(:add_condition).with(@method, @args)
        @klass.send(@method, @args)
      end
    end

    context "if the method doesn't match a column name" do
      it "follows the regular path" do
        expect { @klass.send(@method, @args) }.to raise_exception(NoMethodError)
      end
    end
  end

  describe ".path" do
    it "adds a path condition" do
      args = ["a", "b", "c"]
      @klass.expects(:add_condition).with(:path, any_parameters)
      @klass.path(*args)
    end

    it "joins the arguments with \/, prepending ^/, as a regular expression" do
      args = ["a", "b", "c"]
      @klass.expects(:add_condition).with(anything, Regexp.new("^/" + args.join("\\/")))
      # do |component, condition|
      # this is necessary because there seems to be a weird character set bug with the 
      @klass.path(*args)
    end

    it "turns regular expressions into their string form, joining them" do
      regexp1 = /0-9\_/
      regexp2 = /def/
      args = [regexp1, "b", regexp2]
      expected = args.collect {|s| s.to_s}
      @klass.expects(:add_condition).with(anything, Regexp.new("^/" + expected.join("\\/")))
      @klass.path(*args)
    end

    context "path helper methods" do
      describe ".any_segments" do
        it "returns a regexp for one or more segments" do
          @klass.any_segment.should == /.+/
        end
      end

      # will be factored into a separate Facebook @klass at some point
      describe ".facebook_id" do
        it "returns a regexp for a Facebook ID" do
          @klass.facebook_id.should == /[A-Za-z0-9\_]+/
        end
      end

      describe ".facebook_keyword" do
        it "returns a regexp for a Facebook connection" do
          @klass.facebook_keyword.should == /([a-z]+|videos\/uploaded)/
        end

        it "matches all known special methods" do
          Facebook::ObjectIdentifier::KNOWN_FACEBOOK_OPERATIONS.each do |op| 
            @klass.facebook_keyword.should =~ op
          end
        end

        it "matches all known connections" do
          Facebook::ObjectIdentifier::KNOWN_FACEBOOK_CONNECTIONS.each do |connection| 
            @klass.facebook_keyword.should =~ connection
          end
        end
      end
    end
  end

  describe ".match?" do
    before :each do
      @interaction = ApiInteraction.make
      ApiInteraction.column_names.stubs(:include?).returns(true)      

      @klass.add_condition(:test1, /foo\/bar/)
      @klass.add_condition(:test2, "string")
    end

    it "raises an ArgumentError if not passed an ApiInteraction" do
      expect { @klass.match?(String.new) }.to raise_exception(ArgumentError)
    end

    it "tests each condition against the appropriate attribute" do
      @klass.conditions.each_pair do |attribute, test|
        @klass.expects(:condition_matches?).with(@interaction, attribute, test).returns(true)
      end
      @klass.match?(@interaction)
    end

    it "stops if any test returns false" do
      @klass.stubs(:condition_matches?).with(anything, :test1, anything).returns(false)
      @klass.expects(:condition_matches?).with(anything, :test2, anything).never
      @klass.match?(@interaction)
    end

    it "returns false unless all conditions match" do
      @klass.stubs(:condition_matches?).returns(true)
      @klass.expects(:condition_matches?).with(anything, :test1, anything).returns(false)
      @klass.match?(@interaction).should be_false
    end

    it "returns true if all conditions match" do
      @klass.stubs(:condition_matches?).returns(true)
      @klass.match?(@interaction).should be_true
    end
  end

  describe ".condition_matches?" do
    before :each do
      @interaction = ApiInteraction.make
    end

    it "throws an ArgumentError if the condition isn't a column on ApiInteraction" do
      @interaction.stubs(:respond_to?).returns(false)
      expect { @klass.condition_matches?(@interaction, "foo", "bar") }.to raise_exception(ArgumentError)
    end

    # arguably testing implementation, but these are so basic
    # (we could also test true/false cases instead of using the stubs)
    it "returns truthy if the condition is a Regexp and it matches" do
      method = "verb"
      @interaction.stubs(:verb).returns("test222")
      @klass.condition_matches?(@interaction, method, /test/).should
    end

    it "returns falsy if the condition is a Regexp and it matches" do
      method = "verb"
      @interaction.stubs(:verb).returns("test222")
      @klass.condition_matches?(@interaction, method, /t2est/).should_not
    end

    it "returns truthy if the condition is a string and it's equal" do
      method = "verb"
      @interaction.stubs(:verb).returns("test")
      @klass.condition_matches?(@interaction, method, "test").should be_true
    end

    it "returns false if the condition is a string and it's not equal" do
      method = "verb"
      @interaction.stubs(:verb).returns("test")
      @klass.condition_matches?(@interaction, method, "te2st").should be_false
    end
  end

  describe ".test" do
    before :each do
      @interaction = ApiInteraction.make
    end

    it "raises an ArgumentError if not passed an ApiInteraction" do
      expect { @klass.test(String.new) }.to raise_exception(ArgumentError)
    end

    it "sees if the interaction is a match" do
      @klass.expects(:match?).with(@interaction)
      @klass.test(@interaction)
    end

    context "if it's a match" do
      before :each do
        @record = ApiCall.make! # we expect a save record, << may be used
        @klass.stubs(:find_or_create_api_call).returns(@record)
        @klass.expects(:match?).returns(true)
      end

      it "finds or creates an ApiCall record" do
        @klass.expects(:find_or_create_api_call).with(@interaction).returns(@record)
        @klass.test(@interaction)
      end

      it "returns the found or created ApiCall" do
        @klass.test(@interaction).should == @record
      end

      it "associates this ApiInteraction with the ApiCall" do
        @klass.test(@interaction)
        @interaction.api_call.should == @record
      end

      it "saves the ApiInteraction record" do
        @klass.test(@interaction)
        @interaction.api_call.should == @record
      end      
    end

    context "if not a match" do
      before :each do
        @klass.stubs(:match?).returns(false)
      end

      it "returns nil" do
        @klass.test(@interaction).should be_nil
      end
    end
  end

  describe ".find_or_create_api_call" do
    before :each do
      @interaction = ApiInteraction.make
      @klass.stubs(:get_api_call)
      @klass.stubs(:create_api_call)
    end

    it "looks for a matching record" do
      # protected method, used by subclasses
      @klass.expects(:get_api_call).with(@interaction)
      @klass.find_or_create_api_call(@interaction)
    end

    context "if a matching record exists" do
      it "returns it if found" do
        record = stub("record")
        @klass.stubs(:get_api_call).returns(record)
        @klass.find_or_create_api_call(@interaction).should == record      
      end

      it "doesn't call create_api_call if it finds a record" do
        record = stub("record")
        @klass.stubs(:get_api_call).returns(record)
        @klass.expects(:create_api_call).never
        @klass.find_or_create_api_call(@interaction)
      end
    end

    context "if no matching record exists" do
      it "creates a new record" do
        # that the record created has the appropriate details will be tested in subclasses
        @klass.expects(:create_api_call).with(@interaction)
        @klass.find_or_create_api_call(@interaction)      
      end

      it "returns the created record" do
        record = stub("record")
        @klass.stubs(:create_api_call).returns(record)
        @klass.find_or_create_api_call(@interaction).should == record      
      end
    end
  end
end

shared_examples_for "subclasses of Matcher" do

end