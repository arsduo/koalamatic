require "spec_helper"

describe TestRun do
  
  describe "constants" do
    it "defines TEST_INTERVAL to be 30.minutes" do
      TestRun::TEST_INTERVAL.should == 30.minutes
    end

    it "defines TEST_PADDING to be 10.minutes" do
      TestRun::TEST_PADDING.should == 10.minutes
    end
    
    it "defines PUBLISHING_INTERVAL to be 1.day" do
      TestRun::PUBLISHING_INTERVAL.should == 1.day
    end
  end

  describe "#time_to_next_run" do
    it "returns TEST_INTERVAL - TEST_PADDING" do
      TestRun.time_to_next_run.should == TestRun::TEST_INTERVAL - TestRun::TEST_PADDING
    end
  end
  
  describe "#new" do
    it "sets test_count to 0" do
      TestRun.new.test_count.should == 0
    end

    it "sets failure_count to 0" do
      TestRun.new.failure_count.should == 0
    end
  end

  describe ".test_done" do
    before :each do
      @run = TestRun.make
      @example = make_example(false)
    end 

    it "adds to the test case count" do
      count = @run.test_count
      @run.test_done(@example)
      @run.test_count.should == count + 1
    end

    context "for a pass" do
      it "does not add to the failure count" do
        failure_count = @run.failure_count
        @run.test_done(@example)
        @run.failure_count.should == failure_count
      end
    end

    context "for a failure" do
      before :each do
        @example.stubs(:failed?).returns(true)
      end 
      
      it "adds to the failure count" do
        failure_count = @run.failure_count
        @run.test_done(@example)
        @run.failure_count.should == failure_count + 1
      end
    end
  end

  describe ".done" do
    before :each do
      @start_time = Time.at(3)
      Time.stubs(:now).returns(@start_time)
      @run = TestRun.make
    end

    it "sets the duration" do
      @end_time = Time.at(5)
      Time.stubs(:now).returns(@end_time)
      @run.done
      @run.duration.should == @end_time - @start_time
    end

    it "sets the failure count based on the results" do
      failures = 5
      failures.times.each { @run.test_done(make_example(true))}
      non_failures = 3
      non_failures.times.each { @run.test_done(make_example(false))}
      @run.done
      @run.failure_count.should == failures
    end
    
    context "saving test cases" do
      before :each do
        @failures = 5.times.collect { ex = make_example(true); @run.test_done(ex); ex }
        @passes = 6.times.collect { ex = make_example; @run.test_done(ex); ex }        
      end
      
      it "creates test cases for each failed example" do
        @failures.each {|ex| TestCase.expects(:create_from_example).with(ex).returns(TestCase.make) }
        @run.done
      end
      
      it "does not create test cases for passed examples" do
        # this may change later
        TestCase.stubs(:create_from_example).returns(TestCase.make)
        @passes.each {|ex| TestCase.expects(:create_from_example).with(ex).never.returns(TestCase.make) }
        @run.done
      end      
      
      it "associates those failed records with the test run" do
        cases = []
        @failures.length.times.collect {|i| cases << TestCase.make }
        TestCase.stubs(:create_from_example).returns(*cases)
        @run.done
        cases.each {|c| @run.test_cases.should include(c) }                  
      end
    end

    it "saves the run" do
      @run.done
      @run.should_not be_a_new_record
    end
  end
  
  describe ".summary" do
    it "includes the success text if all's well" do
      TestRun.make.summary.should =~ /#{TestRun::SUCCESS_TEXT}/
    end
  
    it "does not include the success text if there are failures" do
      failures = 3
      TestRun.make(:failure_count => failures).summary.should_not =~ /#{TestRun::SUCCESS_TEXT}/
    end
    
    it "includes the number of failures if > 0" do
      failures = 3
      TestRun.make(:failure_count => failures).summary.should =~ /3/
    end
    
    it "properly pluralizes error" do
      TestRun.make(:failure_count => 1).summary.should =~ /1 error/
      TestRun.make(:failure_count => 1).summary.should_not =~ /1 errors/
      TestRun.make(:failure_count => 2).summary.should =~ /2 errors/
    end
  end

end