require 'digest/md5'
require 'base/version'

module Koalamatic
  module Base
    module VersionTracker
      # base module: include into test framework specific version-tracker

      # in order to compare results across time, we have to be able to know when the code base changed
      # ideally we'd only update the version when there's been a code change that affects the test suite
      # but that's complicated
      # so for now, we'll just track application updates and test gem updates

      # this should never happen in normal practice, since our gems are required by Bundler
      # but perhaps when moving from project to project -- better safe (clear errors) than sorry
      class MissingGemError < StandardError; end

      # we define this in a method rather than a constant because modules don't really have inheritance
      # so overriding this in other modules gets hairy (even with ActiveSupport::Concern)
      extend ActiveSupport::Concern
      
      module ClassMethods
        def test_gems
          []
        end

        def version_class
          Koalamatic::Base::Version
        end

        def track_version!
          current_version = version_info
          unless version = version_class.where(:app_tag => current_version[:app_tag], :test_gems_tag => current_version[:test_gems_tag]).limit(1).first
            version = version_class.create(current_version)
          end
          version
        end

        def version_info
          info = {:app_version => app_version, :test_gem_versions => test_gem_versions}
          info.merge({
            # technically to_s can vary between Ruby versions
            # but presumably any change in Ruby would merit a new version anyway!
            :app_tag => Digest::MD5.hexdigest(info[:app_version].to_s),
            :test_gems_tag => Digest::MD5.hexdigest(info[:test_gem_versions].to_s)
          })
        end

        def app_version
          # we use date, branch, and git-version together
          # (since git-sha will probably differ between Heroku and Github, our canonical reference)
          repo = Git.open(Rails.root)
          {
            :datestamp => File.open(Rails.root).ctime,
            # we could get branch from the sha, but it'd be useful to have it denormalized
            :git_branch => repo.branch.to_s,
            :git_sha => repo.object(repo.branch).sha
          }
        end

        def test_gem_versions
          test_gems.inject({}) do |versions, gem_name|
            rubygem = get_gem(gem_name)
            versions[gem_name] = {
              :git_sha => rubygem.git_version,
              :version => rubygem.version.to_s
            }
            versions
          end
        end

        def get_gem(gem_name)
          rubygem = Bundler.load.specs.find {|s| s.name == gem_name}
          raise MissingGemError, "Unable to find gem #{gem_name} for version tracking!" unless rubygem
          rubygem
        end
      end
    end
  end
end