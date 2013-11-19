#!/usr/bin/ruby

require "rubygems"
require "oauth"
require "json"
require "csv"

class Bot
    '''
    This bot will tweet random lines from a provided file.
    '''
    @@address = URI("https://api.twitter.com/1.1/statuses/update.json")

    def initialize(name, file)
        @name = name
        @file = file
        @consumer_key = nil
        @access_token = nil
        @authenticated = false
    end

    def authenticate()
        # BE CAREFUL with your auth.csv file. This information gives anyone
        # access to control over your twitter bot.
        auth = {}
        CSV.foreach("auth.csv") do |key, value|
            auth[key] = value
        end

        @consumer_key = OAuth::Consumer.new("#{auth["consumer_key"]}",
                                            "#{auth["consumer_secret"]}")
        @access_token = OAuth::Token.new("#{auth["access_token"]}",
                                         "#{auth["access_secret"]}")
        @authenticated = true
    end

    def wait_for_request()
        # In this example, the bot simply tweets whenever it sees ANY user
        # input. This can be easily adjusted to tweet on whatever conditions you
        # wish.
        req = gets.chomp
        if req
            msg = File.readlines(@file).sample
            tweet("#{msg}")
        end
    end

    def tweet(msg)
        if @authenticated
            request = Net::HTTP::Post.new @@address.request_uri
            request.set_form_data("status" => "#{msg}")

            # Set up HTTP
            http = Net::HTTP.new(@@address.host, @@address.port)
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_PEER

            # Issue the request
            request.oauth! http, @consumer_key, @access_token
            http.start
            response = http.request request

            # Parse and print the tweet if successful
            tweeted = nil
            if response.code == '200' then
                tweeted = JSON.parse(response.body)
                puts "Successfully sent: #{tweeted["text"]}"
            else
                puts "Could not send tweet! " +
                    "Code: #{response.code} | Body: #{response.body}"
            end
        else
            # Simply prints a tweet instead of posting one
            puts "#{msg}"
        end
    end
end

simpleBot = Bot.new("Simple Bot", "tweets.txt")
# Comment the line below out to simply print out tweets without sending them.
simpleBot.authenticate()

while true
    begin
        puts "Waiting for a request... (Ctrl-C to exit)"
        simpleBot.wait_for_request()
    rescue Interrupt
        puts "Exiting... "
        break
    end
end

