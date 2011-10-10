module Facebook
  class ObjectIdentifier
    KNOWN_FACEBOOK_OPERATIONS = [
      "comments",
      "search",
      "oauth"
    ]
    
    @@identified_objects = {}
    
    # class methods

    def self.identify_object(url)
      self.new(url).identify
    end 
    
    def self.get_id_from_path(path)
      path.split("/")[1] # 0 is to the left of the leading /
    end
    
    # instance methods    
    attr_reader :object, :url
    
    def initialize(url_or_id)
      # we can analyze URLs or Facebook object IDs
      if url_or_id.is_a?(Addressable::URI)
        @url = url_or_id
        @object = ObjectIdentifier.get_id_from_path(@url.path)
      else
        @object = url_or_id
      end
    end
    
    def identify
      @@identified_objects[@object] ||= identify_from_path || identify_from_facebook || "unknown"
    end
    
    # useful methods for Facebook analysis (hence public)
    def identify_from_path
      if @url
        if using_rest_server?
          # if it's a REST call, we're not directly querying objects
          # need to support beta server
          "rest_api"
        elsif @url.path == "/"
          # we're querying the batch API
          "batch_api"
        elsif KNOWN_FACEBOOK_OPERATIONS.include?(@object)
          "facebook_operation"
        end
      end
      # if we didn't get a URL or can't find the type from the path
      # return nil and try the next technique
    end

    def identify_from_facebook      
      begin
        result = fetch_object_info(@object)
        if !result.is_a?(Hash)
          Rails.logger.warn "Unexpected result for #{@object.inspect}! #{result.inspect}"
          "unknown"
        elsif result["first_name"]
          "user"
        elsif result["username"] && result["category"]
          "page"
        elsif result["images"]
          "image"
        elsif !result["can_remove"].nil? && result["message"]
          # can_remove can be false, but we just want to see if it exists
          "comment"
        elsif result["namespace"]
          "app"
        elsif type = result["type"]
          type
        else
          Rails.logger.warn "Unable to extract type for #{@object.inspect} from result #{result.inspect}"
          nil
        end
      rescue Koala::Facebook::APIError => err
        if err.message =~ /No node specified/
          "probable_facebook_operation"
        else
          Rails.logger.warn "Error getting type: #{err.inspect}"
          "error"
        end
      end
    end
    
    def fetch_object_info
      Koala.with_default_middleware do
        appropriate_api.get_object(@object)
      end
    end

    private

    def appropriate_api
      # we check whether object =~, because comments for a user are prefixed by the user's ID but have more
      token = if !KoalaTest.live_testing_user || @object =~ /#{KoalaTest.app_id.to_s}/
        # no live testing user = just setting things up
        KoalaTest.test_user_api.api.access_token
      elsif KoalaTest.live_testing_friend && @object =~ /#{KoalaTest.live_testing_friend["id"]}/
        KoalaTest.live_testing_friend["access_token"]
      else
        KoalaTest.live_testing_user["access_token"]
      end
      Koala::Facebook::API.new(token)
    end
    
    def using_rest_server?
      @url.host.gsub(/beta\./, "") == Koala::Facebook::REST_SERVER
    end
  end
end