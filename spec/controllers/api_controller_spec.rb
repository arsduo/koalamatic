require 'spec_helper'

describe ApiController do
  
  
  describe "start_run" do
    before :each do
      Kernel.stubs(:system)
    end
    
    context "with no recent test runs" do
      before :each do
        Facebook::TestRun.delete_all
        Facebook::TestRun.make(:created_at => Time.now - Facebook::TestRun.interval_to_next_run - 1.minute).save
      end
      
      it "starts a new run" do
        Kernel.expects(:system).with("bundle exec rake fb:run_tests &")
        get :start_run
      end
      
      it "returns :status => :started" do
        get :start_run
        JSON.parse(response.body)["status"].should == "started"
      end
    end

    context "with a recent test run" do
      before :each do
        Facebook::TestRun.delete_all
        Facebook::TestRun.make(:created_at => Time.now - Facebook::TestRun.interval_to_next_run + 1.minute).save
      end
      
      it "does not start a new run" do
        Kernel.expects(:system).never
        get :start_run
      end
      
      it "returns :status => :too_soon" do
        get :start_run
        JSON.parse(response.body)["status"].should == "too_soon"
      end
      
    end
    
  end  
end