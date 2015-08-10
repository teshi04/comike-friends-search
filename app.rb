# coding: utf-8

require 'yaml'

class ComikeFriendsSearch < Sinatra::Base

  set :server, 'webrick' # unicorn で動かすときは不要っぽい
  set :erb, :escape_html => true

  get '/' do
    erb :index
  end

  post '/' do
    search_screen_name = params[:query]

    friends = get_all_friends(search_screen_name)

    results = []
    if friends.class == String then
      error_message = friends
    else
      # フォローの中からコミケ参加者っぽいユーザを抽出
      friends.each do |friend|
        if friend.name.include?("日目")
          results << friend
        end
      end
    end

    erb :result, :locals => {:results => results, :search_screen_name => search_screen_name, :error_message => error_message}
  end

  def twitter_client
    path = File.expand_path(File.dirname(__FILE__))

    begin
      $settings = YAML::load(open(path+"/twitter.conf"))
    rescue
      puts "config file load failed."
      raise
    end

    Twitter::REST::Client.new do |config|
      config.consumer_key = $settings["consumer_key"]
      config.consumer_secret = $settings["consumer_secret"]
    end
  end

  SLICE_SIZE = 100

  def get_all_friends(screen_name)
    client = twitter_client

    all_friends = []
    begin
      client.friend_ids(screen_name).each_slice(SLICE_SIZE).each do |slice|
        client.users(slice).each do |friend|
          all_friends << friend
        end
      end

      all_friends
    end
  rescue Twitter::Error::TooManyRequests
    "エラー：混雑しています。時間を置いて試してください。"
  rescue Twitter::Error::Unauthorized
    "エラー：鍵付きユーザーはこのアプリを使用できません。"
  rescue Twitter::Error::NotFound
    "エラー：存在しないユーザーです。"
  end


end
