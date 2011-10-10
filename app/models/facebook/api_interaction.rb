require 'facebook/object_identifier'

module Facebook
  class ApiInteraction < Koalamatic::Base::ApiInteraction
    def attributes_from_call(details = {})
      attrs = super

      # now determine which type of object we were querying
      attrs.merge(:primary_object => @env[:primary_object])      
    end
  end
end
