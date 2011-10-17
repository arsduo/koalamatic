require "spec_helper"
require 'base/test_run'

describe Koalamatic::Base::TestRun do
  include Koalamatic::Base

  include Rails.application.routes.url_helpers

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

  describe ".interval_to_next_run" do
    it "returns TEST_INTERVAL - TEST_PADDING" do
      TestRun.interval_to_next_run.should == TestRun::TEST_INTERVAL - TestRun::TEST_PADDING
    end
  end

  it "by default orders id desc" do
    # default scopes are hard to test! but to_sql is a reliable enough way
    found = false
    TestRun.default_scopes.each {|s| found = true if s.to_sql =~ /order by id desc/i}
    found.should be_true
  end

  describe ".time_for_next_run?" do
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

  describe ".new" do
    it "sets test_count to 0" do
      TestRun.new.test_count.should == 0
    end

    it "sets failure_count to 0" do
      TestRun.new.failure_count.should == 0
    end

    it "sets verified failure_count to 0" do
      TestRun.new.verified_failure_count.should == 0
    end
  end

  describe "#without_recording_time" do
    it "processes the block given" do
      done = false
      TestRun.make.without_recording_time do
        done = true
      end
      done.should be_true
    end

    it "doesn't count the time in the block" do
      # fix when the run starts
      run_start_time = Time.now
      Time.stubs(:now).returns(run_start_time)
      @run = TestRun.make

      # now fix when the block timing starts
      block_start_time = run_start_time + 20.seconds
      Time.stubs(:now).returns(block_start_time)
      difference = 20.seconds

      @run.without_recording_time do
        # the block lasts our 20 second difference
        Time.stubs(:now).returns(block_start_time + difference)
      end

      # finally, fix our finished time
      run_end_time = run_start_time + 100.seconds
      Time.stubs(:now).returns(run_end_time)
      @run.done

      # the duration should be the run end - run start time, - again the block time
      # e.g. the block time wasn't counted as actual test time
      @run.duration.should == run_end_time - run_start_time - difference
    end
  end

  describe "#human_time" do
    it "shows the date/time as MM/DD hh:mm" do
      run = TestRun.new(:created_at => Time.zone.parse("2001/12/31 3:45 PM"))
      run.human_time.should == "12/31  3:45 PM"
    end
  end

  describe "#passed?" do
    it "returns true if the verified_failure_count is 0" do
      run = TestRun.new
      run.verified_failure_count = 0
      run.passed?.should be_true
    end

    it "returns false the verified_failure_count is > 0" do
      run = TestRun.new
      run.verified_failure_count = 2
      run.passed?.should be_false
    end

    it "returns false if the verified_failure_count is nil" do
      run = TestRun.new
      run.verified_failure_count = nil
      run.passed?.should be_false
    end

    it "ignores unverified failures" do
      run = TestRun.new
      run.failure_count = 300
      run.verified_failure_count = 0
      run.passed?.should be_true
    end
  end

  describe "#test_done" do
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

      it "does not add to the verified failure count" do
        verified_failure_count = @run.verified_failure_count
        @run.test_done(@example)
        @run.failure_count.should == verified_failure_count
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

      it "adds to the verified_failure_count if it's been verified" do
        verified_failure_count = @run.verified_failure_count
        @example.stubs(:verified_exception?).returns(true)
        @run.test_done(@example)
        @run.verified_failure_count.should == verified_failure_count + 1
      end

      it "does not add to the verified_failure_count if it wasn't verified" do
        verified_failure_count = @run.verified_failure_count
        @example.stubs(:verified_exception?).returns(false)
        @run.test_done(@example)
        @run.verified_failure_count.should == verified_failure_count
      end
    end
  end

  describe "#done" do
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

  describe "#summary" do
    it "includes the success text if all's well" do
      TestRun.make.summary.should =~ /#{TestRun::SUCCESS_TEXT}/
    end

    it "does not include the success text if there are failures" do
      failures = 3
      TestRun.make(:verified_failure_count => failures).summary.should_not =~ /#{TestRun::SUCCESS_TEXT}/
    end

    it "includes the number of failures if > 0" do
      failures = 3
      TestRun.make(:verified_failure_count => failures).summary.should =~ /3/
    end

    it "properly pluralizes error" do
      TestRun.make(:verified_failure_count => 1).summary.should =~ /1 error/
      TestRun.make(:verified_failure_count => 1).summary.should_not =~ /1 errors/
      TestRun.make(:verified_failure_count => 2).summary.should =~ /2 errors/
    end

    it "includes the date if it's publishable_by_interval?" do
      t = TestRun.make
      t.stubs(:publishable_by_interval?).returns(true)
      t.stubs(:publishable_by_results?).returns(false)
      t.summary.should =~ /#{Time.now.strftime("%b %d")}/
    end

    it "does not include the date if it's publishable_by_results?" do
      t = TestRun.make
      t.stubs(:publishable_by_interval?).returns(false)
      t.stubs(:publishable_by_results?).returns(true)
      t.summary.should_not =~ /#{Time.now.strftime("%b %d")}/
    end

    describe "the difference from previous run" do
      it "isn't included if there's no previous run" do
        t = TestRun.make(:verified_failure_count => 3)
        t.stubs(:previous_run).returns(nil)
        t.summary.should_not =~ /last run/
      end

      it "isn't included if the current run passed" do
        t = TestRun.make(:verified_failure_count => 0)
        t.stubs(:previous_run).returns(TestRun.make(:verified_failure_count => 4))
        t.summary.should_not =~ /last run/
      end

      it "isn't included if the previous run passed" do
        t = TestRun.make(:verified_failure_count => 3)
        t.stubs(:previous_run).returns(TestRun.make(:verified_failure_count => 0))
        t.summary.should_not =~ /last run/
      end

      it "isn't included if the previous run had the same number of failures" do
        t = TestRun.make(:verified_failure_count => 3)
        t.stubs(:previous_run).returns(TestRun.make(:verified_failure_count => t.failure_count))
        t.summary.should_not =~ /last run/
      end

      it "is included if the previous run had a different non-zero number of failures" do
        t = TestRun.make(:verified_failure_count => 3)
        t.stubs(:previous_run).returns(TestRun.make(:verified_failure_count => 1))
        t.summary.should =~ /last run/
      end

      it "says more than if there are now more failures than before" do
        t = TestRun.make(:verified_failure_count => 3)
        t.stubs(:previous_run).returns(TestRun.make(:verified_failure_count => 2))
        t.summary.should =~ /more than last run/
      end

      it "says fewer than if there are now fewer failures than before" do
        t = TestRun.make(:verified_failure_count => 3)
        t.stubs(:previous_run).returns(TestRun.make(:verified_failure_count => 5))
        t.summary.should =~ /fewer than last run/
      end
    end

    it "includes the link" do
      run = TestRun.make
      link = "http://foo.bar"
      run.stubs(:url).returns(link)
      run.summary.should include(link)
    end
  end

  describe "#url" do
    before :each do
      @run = TestRun.make
      @run.save
    end

    it "composes a URL including the appropriate server" do
      @run.url.should include(SERVER)
    end

    it "links to /runs/detail/:id" do
      @run.url.should include(url_for(:controller => :runs, :action => :detail, :id => @run.id, :only_path => true))
    end

    it "includes any optional parameters" do
      @run.url(:a => 2).should include("a=2")
    end

    it "links properly even if the run is unsaved" do
      TestRun.new.url.should include(url_for(:controller => :runs, :action => :detail, :id => nil, :only_path => true))
    end
  end

  describe "#previous_run" do
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

  describe "#unverified_failure_count" do
    it "returns the difference between the verified failures and all the failures" do
      test_run_completed(:verified_failure_count => 3, :failure_count => 5).unverified_failure_count.should == 2
    end
  end

  describe "#publishable_by_interval?" do
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

  describe "#publishable_by_results?" do
    it "returns true if the verified failure count != previous verified failure count" do
      run1 = test_run_completed(:verified_failure_count => 3)
      run2 = test_run_completed(:verified_failure_count => 2)
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
      run1 = test_run_completed(:verified_failure_count => 3)
      run2 = test_run_completed(:verified_failure_count => 3)
      run1.save
      run2.save
      run2.publishable_by_results?.should be_false
    end

    it "ignores the unverified failure count" do
      run1 = test_run_completed(:verified_failure_count => 3, :failure_count => 2)
      run2 = test_run_completed(:verified_failure_count => 3, :failure_count => 1)
      run1.save
      run2.save
      run2.publishable_by_results?.should be_false
    end
  end

  describe "#publishable?" do
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

  describe "#publish_if_appropriate!" do
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

  describe ".most_recently_published" do
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

  describe ".last_scheduled_publication" do
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