require "json"
require "sinatra/base"
require "github-trello/version"
require "github-trello/http"

module GithubTrello
  class Server < Sinatra::Base
    #Recieves payload
    post "/posthook-github" do
      #Get environment variables for configuration
        oauth_token = ENV["oauth_token"]
        api_key = ENV["api_key"]
        board_id = ENV["board_id"]
        start_list_target_id = ENV["start_list_target_id"]
        finish_list_target_id = ENV["finish_list_target_id"]
        deployed_list_target_id = ENV["deployed_list_target_id"]

      #Set up HTTP Wrapper
        http = GithubTrello::HTTP.new(oauth_token, api_key)

      #Get payload
        payload = JSON.parse(params[:payload])

      #Get branch
      branch = payload["ref"].gsub("refs/heads/", "")

      payload["commits"].each do |commit|
        # Figure out the card short id
        match = commit["message"].match(/((start|card|close|fix)e?s? \D?([0-9]+))/i)
        next unless match and match[3].to_i > 0

        results = http.get_card(board_id, match[3].to_i)
        unless results
          puts "[ERROR] Cannot find card matching ID #{match[3]}"
          next
        end

        results = JSON.parse(results)

        # Add the commit comment
        message = "#{commit["author"]["name"]}: #{commit["message"]}\n\n[#{branch}] #{commit["url"]}"
        message.gsub!(match[1], "")
        message.gsub!(/\(\)$/, "")

        http.add_comment(results["id"], message)

        #Determine the action to take
        new_list_id = case match[2].downcase
         when "start", "card" then start_list_target_id
         when "close", "fix" then finish_list_target_id
        end

        next unless !new_list_id.nil?
        
        #Modify it if needed
        to_update = {}

        unless results["idList"] == new_list_id
         to_update[:idList] = new_list_id
        end

        unless to_update.empty?
         http.update_card(results["id"], to_update)
        end
      end
      ""
    end

    #Recieves payload
    post "/posthook-heroku" do
      #Get environment variables for configuration
        oauth_token = ENV["oauth_token"]
        api_key = ENV["api_key"]
        board_id = ENV["board_id"]
        start_list_target_id = ENV["start_list_target_id"]
        finish_list_target_id = ENV["finish_list_target_id"]
        deployed_list_target_id = ENV["deployed_list_target_id"]

        puts "Received posthook-heroku"

      #Set up HTTP Wrapper
        http = GithubTrello::HTTP.new(oauth_token, api_key)

      #Get Message
        message = params[:git_log]

        puts message
      #Parse Message and Update Trello
      # Figure out the card short id
        match = message.match(/((start|card|close|fix)e?s? \D?([0-9]+))/i)
        
        if match and match[3].to_i > 0

          puts match[3].to_i

          #Fetch card from Trello
          results = http.get_card(board_id, match[3].to_i)

          unless results
            puts "[ERROR] Cannot find card matching ID #{match[3]}"
            next
          end

          results = JSON.parse(results)
          puts results["id"]
          #Modify it if needed
          to_update = {}

          #Modify card by moving to deployed list
          to_update[:idList] = deployed_list_target_id
          
          unless to_update.empty?
           response = http.update_card(results["id"], to_update)
           puts response
          end

        end
      ""
    end

    get "/" do
      ""
    end

    def self.http; @http end
  end
end