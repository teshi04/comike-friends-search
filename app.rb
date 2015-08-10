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
    comike_text = ["日目", "曜日"]
    results = []
    if friends.class == String then
      error_message = friends
    else
      # フォローの中からコミケ参加者っぽいユーザを抽出
      friends.each do |friend|
        comike_text.any? do |m|
          if friend.name.include?(m)
            results << friend
          end
        end
      end
    end

    # ソート
    day1 = []
    day1_text = ["金曜", "１日目", "1日目", "一日目"]
    results.each do |friend|
      day1_text.any? do |m|
        if friend.name.include?(m)
          day1 << friend
        end
      end
    end

    day2 = []
    day2_text = ["土曜", "２日目", "2日目", "二日目"]
    results.each do |friend|
      day2_text.any? do |m|
        if friend.name.include?(m)
          day2 << friend
        end
      end
    end

    day3 = []
    day3_text = ["日曜", "３日目", "3日目", "三日目"]
    results.each do |friend|
      day3_text.any? do |m|
        if friend.name.include?(m)
          day3 << friend
        end
      end
    end

    erb :result, :locals => {:day1 => day1, :day2 => day2, :day3 => day3, :search_screen_name => search_screen_name, :error_message => error_message}
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
