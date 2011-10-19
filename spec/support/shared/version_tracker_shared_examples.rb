shared_examples_for "a version tracker" do
  
  describe ".track_version!" do
    before :each do
      @tracker_class.version_class.stubs(:create)
      @tracker_class.version_class.stubs(:where).returns(@tracker_class.version_class)
      # need to see if there are stubbing libraries for working with Arel -- this is hooking too much into internal implementation
      @tracker_class.version_class.stubs(:limit).returns([])
      @current_version = {
        :test_gems_tag => [],
        :app_tag => []
      }
      @tracker_class.stubs(:version_info).returns(@current_version)
    end

    it "gets all the version info" do
      @tracker_class.expects(:version_info).returns({})
      @tracker_class.track_version!
    end

    it "sees if there's a previous version with the same app and test gems tags" do
      @tracker_class.version_class.expects(:where).with(:app_tag => @current_version[:app_tag], :test_gems_tag => @current_version[:test_gems_tag]).returns(@tracker_class.version_class)
      @tracker_class.track_version!
    end
    
    it "returns the previous matching version record if one exists" do
      version = stub("version")
      @tracker_class.version_class.expects(:limit).returns([version])
      @tracker_class.track_version!.should == version
    end
    
    it "creates a new version if there's no matching record" do      
      @tracker_class.version_class.expects(:create).with(@current_version)
      @tracker_class.version_class.expects(:limit).returns([])
      @tracker_class.track_version!
    end
    
    it "creates a new version if there's no matching record" do      
      version = stub("version")
      @tracker_class.version_class.stubs(:create).returns(version)
      @tracker_class.version_class.expects(:limit).returns([])
      @tracker_class.track_version!.should == version
    end
  end

  describe ".version_info" do
    before :each do
      @app_version = stub("app_version", :to_s => Faker::Lorem.words(5).join(" "))
      @test_gem_versions = stub("app_version", :to_s => Faker::Lorem.words(5).join(" "))
      @app_tag = stub("app_tag")
      @test_gems_tag = stub("gems_tag")
      @tracker_class.stubs(:test_gem_versions).returns(@test_gem_versions)
      @tracker_class.stubs(:app_version).returns(@app_version)
      Digest::MD5.stubs(:hexdigest).with(@app_version.to_s).returns(@app_tag)
      Digest::MD5.stubs(:hexdigest).with(@test_gem_versions.to_s).returns(@test_gems_tag)
    end
    
    it "gets the app_version info" do
      @tracker_class.expects(:app_version).returns(@app_version)
      @tracker_class.version_info
    end
    
    it "returns a hash with :app => the app_version" do
      @tracker_class.version_info[:app_version].should == @app_version
    end
    
    it "gets the test_gem_versions info" do
      @tracker_class.expects(:test_gem_versions).returns(@test_gem_versions)
      @tracker_class.version_info
    end

    it "returns a hash with :test_gem_versions => the test_gem_versions" do
      @tracker_class.version_info[:test_gem_versions].should == @test_gem_versions
    end
    
    it "calculates Digest::MD5.hexdigest of the app version info as a string" do
      Digest::MD5.expects(:hexdigest).with(@app_version.to_s).returns(@app_tag)
      @tracker_class.version_info
    end

    it "returns a hash with :app_tag => the digested app_version" do
      @tracker_class.version_info[:app_tag].should == @app_tag
    end

    it "calculates Digest::MD5.hexdigest of the app version info as a string" do
      Digest::MD5.expects(:hexdigest).with(@test_gem_versions.to_s).returns(@test_gems_tag)
      @tracker_class.version_info
    end

    it "returns a hash with :app_tag => the digested app_version" do
      @tracker_class.version_info[:test_gems_tag].should == @test_gems_tag
    end
  end

  describe ".app_version" do
    before :each do
      @git = stub("git repo", :branch => stub("master", :to_s => "master2"))
      @git.stubs(:object).with(@git.branch).returns(stub("git object", :sha => stub("sha")))
      Git.stubs(:open).returns(@git)
    end
    
    it "gets git data for the Rails project" do
      # ensure we're using the git stubs we set up
      Git.expects(:open).with(Rails.root).returns(@git)
      @tracker_class.app_version
    end
    
    it "returns a hash with datestamp => ctime of the Rails project directory" do
      time = stub("time")
      File.expects(:open).with(Rails.root).returns(stub("time object", :ctime => time))
      @tracker_class.app_version[:datestamp].should == time
    end

    
    it "returns a hash with git_branch => the git branch.to_s" do
      @tracker_class.app_version[:git_branch].should == @git.branch.to_s
    end

    it "returns a hash with git_sha => the git branch's sha" do
      @tracker_class.app_version[:git_sha].should == @git.object(@git.branch).sha
    end    
  end

  describe ".test_gem_versions" do
    before :each do
      @stubs = {}
      @tracker_class.stubs(:test_gems).returns(3.times.collect { Faker::Lorem.words(1).join })
      @tracker_class.test_gems.each do |gem_name|
        new_stub = stub(gem_name, :git_version => Faker::Lorem.words(1), :version => Faker::Lorem.words(2).join("."))
        @stubs[gem_name] = new_stub
        @tracker_class.stubs(:get_gem).with(gem_name).returns(new_stub)
      end
    end

    it "gets each gem" do
      @tracker_class.test_gems.each do |gem_name|
        @tracker_class.expects(:get_gem).with(gem_name).returns(@stubs[gem_name])
      end
      @tracker_class.test_gem_versions
    end

    it "returns a hash keyed to each gem's name" do
      @tracker_class.test_gem_versions.keys.should include(*(@tracker_class.test_gems))
    end

    context "for each gem" do
      it "includes its git_version as git_sha, if the gem is from git" do
        versions = @tracker_class.test_gem_versions
        @tracker_class.test_gems.each do |gem_name|
          versions[gem_name][:git_sha].should == @stubs[gem_name].git_version
        end
      end

      it "returns git_sha = nil if the gem isn't from git" do
        first_gem = @tracker_class.test_gems.first
        @stubs[first_gem].stubs(:git_version).returns(nil)

        @tracker_class.test_gem_versions[first_gem][:git_sha].should be_nil
      end

      it "includes each gem's version" do
        versions = @tracker_class.test_gem_versions
        @tracker_class.test_gems.each do |gem_name|
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
      @tracker_class.get_gem(name).should == gem_stub
    end

    it "raises a MissingGemError if the gem can't be found" do
      name = Faker::Lorem.words(2).join("-")
      Bundler.load.stubs(:specs).returns([stub("other gem", :name => "other"), stub("other gem2", :name => "other2")])
      expect { @tracker_class.get_gem(name) }.to raise_exception(@tracker_class::MissingGemError)
    end
  end
end