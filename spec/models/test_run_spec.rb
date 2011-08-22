require "spec_helper"

describe TestRun do
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
  end

end