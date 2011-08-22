require 'spec_helper'

class VanillaController < ApplicationController
  include MobileControllerExtensions
  def act
    render :text => ""
  end
end

describe ApplicationController do
  it "includes MobileControllerExtensions" do
    controller.class.included_modules.should include MobileControllerExtensions
  end  
end

describe VanillaController do
  include RSpec::Rails::ControllerExampleGroup
  describe "universal before_filters" do
    before :all do
      @controller_name = "vanilla"
      @action_name = "act"
      Postkart::Application.routes.draw do
        get "#{@controller_name}/#{@action_name}", :controller => :vanilla, :action => :act
      end    
    end
  
    after :all do
      # restore all routes
      Postkart::Application.reload_routes!
    end
  
    describe ".detect_contact_reload" do
      it "works" do
        raise Exception, "it doesn't"
      end
      
      it "sets flash[:reloadData] = true if params[:reloadData]" do
        get @action_name, :reloadData => 1
        flash[:reloadData].should be_true
      end
    
      it "redirects to the page w/o the mobile flag if it's present" do
        params = HashWithIndifferentAccess.new(:reloadData => 1, :foo => "bar", :controller => @controller_name, :action => @action_name)
        controller.expects(:redirect_to).with(params.dup.delete_if {|k, v| k.to_sym == :reloadData})
        get @action_name, params
      end
    end
  end
end
