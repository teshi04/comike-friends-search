# coding: utf-8

require 'yaml'

class TwiSearch < Sinatra::Base

  set :server, 'webrick' # unicornで動かすときはいらないっぽい
  set :erb, :escape_html => true

  path = File.expand_path(File.dirname(__FILE__))

  begin
    $settings = YAML::load(open(path+"/twitter.conf"))
  rescue
    puts "config file load failed."
    raise
  end

  client = Twitter::REST::Client.new do |config|
   config.consumer_key = $settings["consumer_key"]
   config.consumer_secret = $settings["consumer_secret"]
  end

  get '/' do
    search_word = params[:query]

    results = client.search(search_word, :result_type => "recent").collect do |tweet|
      if tweet.text.include?(search_word) && tweet.user_mentions.all? { |mention| !mention.screen_name.include?(search_word) }
          tweet
      end
    end

    # escape nil
    results = results.compact

    erb :result, :locals => {:results => results, :search_word => search_word }
  end
end
