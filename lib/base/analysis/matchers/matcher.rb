module Koalamatic
  module Base
    module Analysis
      class ApiCallMatcher
        def self.match?(interaction)
        end

        @matchers = {}

        def self.match?(interaction)
          @matchers.each_pair do |attribute, match_data|
            # evaluate each of the declared matchers, aborting the match if it returns false
            return false unless evaluate_match(interaction.send(attribute), match_data)
          end
          # if all the matchers returned true, we have a match
          true
        end

        def self.method_missing(name, *args, &block)
          if interaction_class.column_names.include?(name.to_s)
            # we're matching against a column
            @matchers[name] = {:args => args, :block => block}
          else
            super
          end
        end

        protected

        def self.evaluate_match(value, match_data)
          valid = if match_data[:block]
            match_data.c
          end
        end

      end
    end
  end
end