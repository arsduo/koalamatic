module Facebook
  module ObjectIdentifier
    KNOWN_FACEBOOK_OPERATIONS = [
      "comments",
      "search",
      "oauth"
    ]

    def self.identify_object(url)
      identify_from_path(url) || identify_from_facebook(url) || "unknown"
    end
    
    # useful methods for Facebook analysis (hence public)
    def self.identify_from_path(url)
      object = get_id_from_path(url.path) 
      if using_rest_server?(url)
        # if it's a REST call, we're not directly querying objects
        # need to support beta server
        "rest_api"
      elsif url.path == "/"
        # we're querying the batch API
        "batch_api"
      elsif KNOWN_FACEBOOK_OPERATIONS.include?(object)
        "facebook_operation"
      end
      # if we can't find the type from the path, then try the next technique
    end

    def self.identify_from_facebook(url)
      object = get_id_from_path(url.path) 
      begin
        result = fetch_object_info(object)

        if !result.is_a?(Hash)
          Rails.logger.warn "Unexpected result for #{object.inspect}! #{result.inspect}"
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
          Rails.logger.warn "Unable to extract type for #{object} from result #{result.inspect}"
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
    
    def self.fetch_object_info(object)
      Koala.with_default_middleware do
        api_for_object(object).get_object(object)
      end
    end
    
    def self.get_id_from_path(path)
      path.split("/")[1] # 0 is to the left of the leading /
    end

    private

    def self.api_for_object(object)
      # we check whether object =~, because comments for a user are prefixed by the user's ID but have more
      puts "Identifying #{object}"
      puts (object =~ /#{KoalaTest.live_testing_friend["id"]}/) if KoalaTest.live_testing_friend.inspect 
      token = if !KoalaTest.live_testing_user || object =~ /#{KoalaTest.app_id.to_s}/
        # no live testing user = just setting things up
        KoalaTest.test_user_api.api.access_token
      elsif KoalaTest.live_testing_friend && object =~ /#{KoalaTest.live_testing_friend["id"]}/
        KoalaTest.live_testing_friend["access_token"]
      else
        KoalaTest.live_testing_user["access_token"]
      end
      Koala::Facebook::API.new(token)
    end
    
    def self.using_rest_server?(url)
      url.host.gsub(/beta\./, "") == Koala::Facebook::REST_SERVER
    end
  end
end