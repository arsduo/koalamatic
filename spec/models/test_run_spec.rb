require "spec_helper"

describe TestRun do
  
  describe "constants" do
    it "defines TEST_INTERVAL to be 60.minutes" do
      TestRun::TEST_INTERVAL.should == 60.minutes
    end

    it "defines TEST_PADDING to be 10.minutes" do
      TestRun::TEST_PADDING.should == 10.minutes
    end
    
    it "defines PUBLISHING_INTERVAL to be 1.day" do
      TestRun::PUBLISHING_INTERVAL.should == 1.day
    end
  end
  describe "#interval_to_next_run" do
    it "returns TEST_INTERVAL - TEST_PADDING" do
      TestRun.interval_to_next_run.should == TestRun::TEST_INTERVAL - TestRun::TEST_PADDING
    end
  end

  describe "#time_for_next_run?" do
    before :each do
      TestRun.destroy_all
    end
      
    it "returns true if there's no test within the last TEST_INTERVAL - TEST_PADDING seconds" do
      TestRun.make(:created_at => Time.now - TestRun.interval_to_next_run - 1.second).save
      TestRun.time_for_next_run?.should be_true
    end
    
    it "returns false if there's a test within the last TEST_INTERVAL - TEST_PADDING seconds" do
      TestRun.make(:created_at => Time.now - TestRun.interval_to_next_run + 1.second).save  
      TestRun.time_for_next_run?.should be_false
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
    
    it "includes the date if it's publishable_by_interval?"
    it "does not include the date if it's publishable_by_results?"
    it "properly includes a comparison to previous results if there are previous results"
    it "works if there are no previous results"    
  end
  
  describe "previous run" do
    before :each do
      TestRun.make.save
      TestRun.make.save
      @run = TestRun.make
      @run.save
      @run2 = TestRun.make
      @run2.save
    end
    
    it "gets the previous run" do
      @run2.previous_run.should == @run
    end 
    
    it "doesn't make two database calls if called twice" do
      @run2.previous_run
      TestRun.expects(:where).never
      TestRun.expects(:find).never
      @run2.previous_run
    end   
  end
  
  describe ".publishable_by_interval?" do
    it "returns true if the last scheduled publication is < publishing interval" do
      old_run = TestRun.make(:created_at => Time.now - TestRun::PUBLISHING_INTERVAL - 1.minute)
      old_run.save
      TestRun.stubs(:last_scheduled_publication).returns(old_run)
      test_run_completed.publishable_by_interval?.should be_true
    end

    it "returns true if the last scheduled publication is > publishing interval" do
      old_run = TestRun.make(:created_at => Time.now - TestRun::PUBLISHING_INTERVAL + 1.minute)
      old_run.save
      TestRun.stubs(:last_scheduled_publication).returns(old_run)
      test_run_completed.publishable_by_interval?.should be_false
    end    
    
    it "returns true if there are no previous test runs" do
      TestRun.stubs(:last_scheduled_publication).returns(nil)
      TestRun.new.publishable_by_interval?.should be_true
    end
  end
  
  describe ".publishable_by_results?" do
    it "returns true if the failure count != previous failure count" do
      run1 = test_run_completed(:failure_count => 3)
      run2 = test_run_completed(:failure_count => 2)
      run1.save
      run2.save
      run2.publishable_by_results?.should be_true
    end
    
    it "returns true if there are no previous applicable test runs" do
      run = TestRun.new
      run.stubs(:previous_run).returns(nil)
      run.publishable_by_results?.should be_true
    end
    
    it "returns false if the failure count == previous failure count" do
      run1 = test_run_completed(:failure_count => 3)
      run2 = test_run_completed(:failure_count => 3)
      run1.save
      run2.save
      run2.publishable_by_results?.should be_false
    end
  end
  
  describe ".publishable?" do
    before :each do
      @run = TestRun.make
    end
    
    it "sets publication_reason to SCHEDULED_REASON if it's publishable_by_interval?" do
      @run.stubs(:publishable_by_interval?).returns(true)
      @run.stubs(:publishable_by_results?).returns(false)
      @run.publishable?
      @run.publication_reason.should == TestRun::SCHEDULED_REASON
    end
    
    it "sets publication_reason to DIFFERENT_RESULTS_REASON if it's publishable_by_interval?" do
      @run.stubs(:publishable_by_interval?).returns(false)
      @run.stubs(:publishable_by_results?).returns(true)
      @run.publishable?
      @run.publication_reason.should == TestRun::DIFFERENT_RESULTS_REASON
    end
    
    it "sets publication_reason to nil otherwise" do
      @run.stubs(:publishable_by_interval?).returns(false)
      @run.stubs(:publishable_by_results?).returns(false)
      @run.publishable?
      @run.publication_reason.should be_nil
    end    
    
    it "returns true if it's publishable_by_interval?" do
      @run.stubs(:publishable_by_interval?).returns(true)
      @run.stubs(:publishable_by_results?).returns(false)
      @run.publishable?.should be_true
    end
    
    it "returns true if it's publishable_by_interval?" do
      @run.stubs(:publishable_by_interval?).returns(false)
      @run.stubs(:publishable_by_results?).returns(true)
      @run.publishable?.should be_true
    end
    
    it "returns false otherwise" do
      @run.stubs(:publishable_by_interval?).returns(false)
      @run.stubs(:publishable_by_results?).returns(false)
      @run.publishable?.should be_false
    end
    
  end

  describe ".publish_if_appropriate!" do
    before :each do
      @run = TestRun.make
      @tweet = stub("Tweet", :id => rand(2**25))    
      @run.stubs(:summary).returns("my summary")  
      Twitter.stubs(:update).returns(@tweet)
    end
  
    it "does nothing if it's not publishable" do
      @run.expects(:publishable?).returns(false)
      Twitter.expects(:update).never
      @run.publish_if_appropriate!
    end
    
    it "publishes the summary as a tweet" do
      @run.stubs(:publishable?).returns("true")
      summary = "abcdefg"
      @run.expects(:summary).returns(summary)
      Twitter.expects(:update).with(summary).returns(@tweet)
      @run.publish_if_appropriate!
    end

    it "saves the tweet ID" do
      @run.expects(:publishable?).returns("true")      
      @run.publish_if_appropriate!
      @run.tweet_id.should == @tweet.id      
    end
    
    it "saves the record" do
      @run.stubs(:publishable?).returns("true")      
      @run.publish_if_appropriate!
      @run.changed?.should be_false
    end    
  end

  describe "#most_recently_published" do
    it "gets the most recent published post" do
      run = test_run_completed
      run.save
      TestRun.most_recently_published.should == run
    end
    
    it "ignores runs that weren't published" do
      test_run_completed(:created_at => Time.now + 1.hour, :tweet_id => nil).save
      run = test_run_completed
      run.save
      TestRun.most_recently_published.should == run
    end
  end
  
  describe "#last_scheduled_publication" do
    it "gets the most recently scheduled post" do
      run = test_run_completed(:publication_reason => TestRun::SCHEDULED_REASON)
      run.save
      TestRun.most_recently_published.should == run
    end
    
    it "ignores runs that weren't published" do
      # shouldn't happen, but worth checking
      test_run_completed(:created_at => Time.now + 1.hour, :tweet_id => nil, :publication_reason => TestRun::SCHEDULED_REASON).save
      run = test_run_completed
      run.save
      TestRun.most_recently_published.should == run
    end
    
    it "ignores runs that were published because of changed results" do
      test_run_completed(:created_at => Time.now + 1.hour, :publication_reason => TestRun::DIFFERENT_RESULTS_REASON).save
      run = test_run_completed
      run.save
      TestRun.most_recently_published.should == run
    end 
  end
end