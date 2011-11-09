module Koalamatic
  module Base
    module Analysis
      class Matcher
        class << self
          attr_accessor :conditions
          def conditions
            # ensure conditions are available for subclasses immediately
            # (since they don't inherit instance variables)
            @conditions ||= {}
          end

          def add_condition(name, condition = nil, &block)
            raise ArgumentError, "You must specify argument or a block for add_condition / dynamic condition statements" if condition.blank? && !block
            # store a single matcher as itself, multiples in an array, and if none provided, the block
            conditions[name] = condition || block
          end

          def method_missing(method_name, *args, &block)
            if ApiInteraction.column_names.include?(method_name.to_s)
              # we define this on the base matcher class, so that it's available to all matchers
              # it took some experimentation to figure out the right object to eval against
              Koalamatic::Base::Analysis::Matcher.class.class_eval <<-DEFINING
                define_method(:#{method_name}) do |*args, &block|
                  add_condition(:#{method_name}, args[0], &block)
                end
              DEFINING
              
              self.send(method_name, *args, &block)
            else
              # raise
              super
            end
          end
          
          def path(*args, &block)
            if args.length > 0
              add_condition(:path, Regexp.new("^/#{args.collect {|a| process_path_component(a) }.join("\\/")}"))
            else
              add_condition(:path, &block)
            end
          end

          private

          def process_path_component(component)
            raise ArgumentError, "Received path component #{component.inspect}, not a String or Regexp" unless component.is_a?(String) || component.is_a?(Regexp)
            # turn it into a string and prepend it with a /            
            "#{component.to_s}"
          end
        end # class << self

        
=begin

      def self.match?(interaction)
      end


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
=end
      end
    end
  end
end