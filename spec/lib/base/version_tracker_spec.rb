require 'spec_helper'
require 'base/version_tracker'

describe Koalamatic::Base::VersionTracker do
  include Koalamatic::Base

  it "defines a MissingGemError < StandardError" do
    VersionTracker::MissingGemError.superclass.should == StandardError
  end
  
  describe ".test_gems" do
    it "has a test_gems array" do
      VersionTracker.test_gems.should be_an(Array)
    end
    
    it "is read-only" do
      VersionTracker.should_not respond_to(:test_gems=)
    end
  end

  describe ".track_version!" do
    before :each do
      Version.stubs(:create)
      Version.stubs(:where).returns(Version)
      # need to see if there are stubbing libraries for working with Arel -- this is hooking too much into internal implementation
      Version.stubs(:limit).returns([])
      @current_version = {
        :test_gems_tag => [],
        :app_tag => []
      }
      VersionTracker.stubs(:version_info).returns(@current_version)
    end

    it "gets all the version info" do
      VersionTracker.expects(:version_info).returns({})
      VersionTracker.track_version!
    end

    it "sees if there's a previous version with the same app and test gems tags" do
      Version.expects(:where).with(:app_tag => @current_version[:app_tag], :test_gems_tag => @current_version[:test_gems_tag]).returns(Version)
      VersionTracker.track_version!
    end

    it "returns the previous matching version record if one exists" do
      version = stub("version")
      Version.expects(:limit).returns([version])
      VersionTracker.track_version!.should == version
    end

    it "creates a new version if there's no matching record" do      
      Version.expects(:create).with(@current_version)
      Version.expects(:limit).returns([])
      VersionTracker.track_version!
    end

    it "creates a new version if there's no matching record" do      
      version = stub("version")
      Version.stubs(:create).returns(version)
      Version.expects(:limit).returns([])
      VersionTracker.track_version!.should == version
    end
  end

  describe ".version_info" do
    before :each do
      @app_version = stub("app_version", :to_s => Faker::Lorem.words(5).join(" "))
      @test_gem_versions = stub("app_version", :to_s => Faker::Lorem.words(5).join(" "))
      @app_tag = stub("app_tag")
      @test_gems_tag = stub("gems_tag")
      VersionTracker.stubs(:test_gem_versions).returns(@test_gem_versions)
      VersionTracker.stubs(:app_version).returns(@app_version)
      Digest::MD5.stubs(:hexdigest).with(@app_version.to_s).returns(@app_tag)
      Digest::MD5.stubs(:hexdigest).with(@test_gem_versions.to_s).returns(@test_gems_tag)
    end

    it "gets the app_version info" do
      VersionTracker.expects(:app_version).returns(@app_version)
      VersionTracker.version_info
    end

    it "returns a hash with :app => the app_version" do
      VersionTracker.version_info[:app_version].should == @app_version
    end

    it "gets the test_gem_versions info" do
      VersionTracker.expects(:test_gem_versions).returns(@test_gem_versions)
      VersionTracker.version_info
    end

    it "returns a hash with :test_gem_versions => the test_gem_versions" do
      VersionTracker.version_info[:test_gem_versions].should == @test_gem_versions
    end

    it "calculates Digest::MD5.hexdigest of the app version info as a string" do
      Digest::MD5.expects(:hexdigest).with(@app_version.to_s).returns(@app_tag)
      VersionTracker.version_info
    end

    it "returns a hash with :app_tag => the digested app_version" do
      VersionTracker.version_info[:app_tag].should == @app_tag
    end

    it "calculates Digest::MD5.hexdigest of the app version info as a string" do
      Digest::MD5.expects(:hexdigest).with(@test_gem_versions.to_s).returns(@test_gems_tag)
      VersionTracker.version_info
    end

    it "returns a hash with :app_tag => the digested app_version" do
      VersionTracker.version_info[:test_gems_tag].should == @test_gems_tag
    end
  end

  describe ".app_version" do
    before :each do
      @git = stub("git repo", :branch => stub("master", :to_s => "master2"))
      @git.stubs(:object).with(@git.branch).returns(stub("git object", :sha => stub("sha")))
      Git.stubs(:open).returns(@git)
    end

    context "if there's git data" do
      it "gets git data for the Rails project" do
        # ensure we're using the git stubs we set up
        Git.expects(:open).with(Rails.root).returns(@git)
        VersionTracker.app_version
      end

      it "returns a hash with git_branch => the git branch.to_s" do
        VersionTracker.app_version[:git_branch].should == @git.branch.to_s
      end

      it "returns a hash with git_sha => the git branch's sha" do
        VersionTracker.app_version[:git_sha].should == @git.object(@git.branch).sha
      end    
    end

    context "if there's no git data" do
      it "doesn't return git data" do
        Git.stubs(:open).raises(StandardError)
        version = VersionTracker.app_version
        version.should_not include(:git_sha, :git_branch)
      end
    end

    it "returns a hash with datestamp => ctime.to_i of the Rails project directory" do
      time = stub("time", :to_i => rand(100000))
      File.expects(:open).with(Rails.root).returns(stub("time object", :ctime => time))
      VersionTracker.app_version[:datestamp].should == time.to_i
    end
  end

  describe ".test_gem_versions" do
    before :each do
      @stubs = {}
      VersionTracker.stubs(:test_gems).returns(3.times.collect { Faker::Lorem.words(1).join })
      VersionTracker.test_gems.each do |gem_name|
        new_stub = stub(gem_name, :git_version => Faker::Lorem.words(1), :version => Faker::Lorem.words(2).join("."))
        @stubs[gem_name] = new_stub
        VersionTracker.stubs(:get_gem).with(gem_name).returns(new_stub)
      end
    end

    it "gets each gem" do
      VersionTracker.test_gems.each do |gem_name|
        VersionTracker.expects(:get_gem).with(gem_name).returns(@stubs[gem_name])
      end
      VersionTracker.test_gem_versions
    end

    it "returns a hash keyed to each gem's name" do
      VersionTracker.test_gem_versions.keys.should include(*(VersionTracker.test_gems))
    end

    context "for each gem" do
      it "includes its git_version as git_sha, if the gem is from git" do
        versions = VersionTracker.test_gem_versions
        VersionTracker.test_gems.each do |gem_name|
          versions[gem_name][:git_sha].should == @stubs[gem_name].git_version
        end
      end

      it "returns git_sha = nil if the gem isn't from git" do
        first_gem = VersionTracker.test_gems.first
        @stubs[first_gem].stubs(:git_version).returns(nil)

        VersionTracker.test_gem_versions[first_gem][:git_sha].should be_nil
      end

      it "includes each gem's version" do
        versions = VersionTracker.test_gem_versions
        VersionTracker.test_gems.each do |gem_name|
          versions[gem_name][:version].should == @stubs[gem_name].version
        end
      end
    end

  end

  describe ".get_gem" do
    it "gets the gem with the matching name from Bundler" do
      name = Faker::Lorem.words(2).join("-")
      gem_stub = stub("gem", :name => name)
      Bundler.load.stubs(:specs).returns([stub("other gem", :name => "other"), gem_stub, stub("other gem2", :name => "other2")])
      VersionTracker.get_gem(name).should == gem_stub
    end

    it "raises a MissingGemError if the gem can't be found" do
      name = Faker::Lorem.words(2).join("-")
      Bundler.load.stubs(:specs).returns([stub("other gem", :name => "other"), stub("other gem2", :name => "other2")])
      expect { VersionTracker.get_gem(name) }.to raise_exception(VersionTracker::MissingGemError)
    end
  end
end