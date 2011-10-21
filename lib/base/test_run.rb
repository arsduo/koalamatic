require 'base/test_case'
require 'base/version_tracker'

module Koalamatic
  module Base
    class TestRun < ActiveRecord::Base
      # note: for now, test_cases only tracks failures
      has_many :test_cases
      has_many :api_interactions
      
      # subclasses can redeclare version with different class names if needed
      belongs_to :version

      include Rails.application.routes.url_helpers

      # how often we ideally want to run tests
      TEST_INTERVAL = 60.minutes
      # roughly how long the tests take to run
      # we subtract this from TEST_INTERVAL when looking up the last test
      # (since the record is created when the test finishes)
      TEST_PADDING = 10.minutes
      # how often we publish on twitter
      PUBLISHING_INTERVAL = 1.day
      DIFFERENT_RESULTS_REASON = "different_results"
      SCHEDULED_REASON = "scheduled"

      def self.interval_to_next_run
        TEST_INTERVAL - TEST_PADDING
      end

      def self.time_for_next_run?
        !TestRun.where(["created_at > ?", Time.now - interval_to_next_run]).limit(1).first
      end

      scope :published, :conditions => "tweet_id is not null", :order => "id desc"
      scope :scheduled, :conditions => "publication_reason  = 'scheduled'", :order => "id desc"

      def initialize(*args)
        super
        @processing_time = 0
        @failures = []
        @start_time = Time.now
        self.failure_count = self.verified_failure_count = 0

        # track the version for this test run so we know which code base it was run against
        # is it bad form to run track_version! (which can create a record) in the initializer?
        # of course, there's no real harm in tracking versions
        # even if something prevents them from ever getting a test run
        self.version = VersionTracker.track_version!
      end

      def test_done(example)
        self.test_count += 1
        if example.failed?
          @failures << example
          self.failure_count += 1
          self.verified_failure_count += 1 if example.verified_exception?
        end
      end

      def done
        # write out to the database
        self.duration = Time.now - @start_time - @processing_time
        # right now we only store details for failures
        # but may in the future store analytic data on successes
        @failures.each do |example|
          test_cases << TestCase.create_from_example(example)
        end

        if saved = self.save
          logger.info("Run #{self.id} completed.")
        else
          logger.warn("Unable to save #{self.inspect} due to: #{self.errors.inspect}")
        end

        saved
      end

      def without_recording_time(&block)
        pause_start = Time.now
        yield
        @processing_time += Time.now - pause_start
      end

      def human_time
        # human-readable identifier for when the run occurred
        created_at.strftime("%m/%d %l:%M %p")
      end

      def passed?
        verified_failure_count && verified_failure_count == 0
      end

      # PUBLISHING
      # this should perhaps be split out into a has_publishing module
      SUCCESS_TEXT = "All's well with the service!"
      def summary
        if publishable?
          text = self.publication_reason == SCHEDULED_REASON ? "Run for #{Time.now.strftime("%b %d")}: " : "Run completed: "

          if (failures = self.verified_failure_count) == 0
            text += SUCCESS_TEXT
          else
            text += "#{failures} error#{failures > 1 ? "s" : ""}"
            difference = previous_run.try(:verified_failure_count).to_i > 0 ? previous_run.verified_failure_count.to_i - failures : 0
            text += " -- #{difference.abs} #{difference > 0 ? "fewer" : "more"} than last run." if difference != 0
          end

          text += " #{url}"
        end
      end

      def url(extra_params = {})
        url_for({:controller => :runs, :action => :detail, :id => self.id, :host => SERVER}.merge(extra_params))
      end

      def previous_run
        @previous ||= TestRun.where(["id < ?", self.id]).order("id desc").limit(1).first
      end

      def unverified_failure_count
        self.failure_count - self.verified_failure_count
      end

      def publishable_by_interval?
        (last_run = TestRun.last_scheduled_publication) ? last_run.created_at < Time.now - PUBLISHING_INTERVAL : true
      end

      def publishable_by_results?
        # this needs to be refined to examine the actual contents of the errors
        !previous_run || verified_failure_count != previous_run.verified_failure_count
      end

      def publishable?
        # see if it's time to publish again
        # is it bad form for a ? method to return strings for later use?
        set_publication_reason
        !!self.publication_reason
      end

      def publish_if_appropriate!
        if self.publishable?
          publication = Twitter.update(summary)
          self.tweet_id = publication.id
          # publication_reason is set in publishable?
          status = self.save
        end
      end

      # class methods

      def self.most_recently_published
        published.first
      end

      def self.last_scheduled_publication
        published.scheduled.first
      end

      private

      def set_publication_reason
        self.publication_reason = if publishable_by_interval?
          SCHEDULED_REASON
          # alternately, see if this run has produced different results
        elsif publishable_by_results?
          DIFFERENT_RESULTS_REASON
        else
          nil
        end
      end

    end
  end
end
