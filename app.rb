require 'date'
require 'slack'
require 'esa'
require 'json'
require 'uri'
require 'net/http'
require 'time'
require 'yaml'

config = YAML.load_file("config.yml")


ESA_ACCESS_TOKEN = config["esa"]["access_token"]
ESA_CURRENT_TEAM = config["esa"]["current_team"]
SLACK_ACCESS_TOKEN = config["slack"]["access_token"]
SLACK_CHANNEL_NAME = config["slack"]["channel_name"]
SLACK_USERNAME = config["slack"]["username"]

Slack.configure do |config|
  config.token =SLACK_ACCESS_TOKEN
end

class Message
  attr_reader :username, :text, :channel, :link

  def initialize(obj)
    @username = obj["username"]
    @text = obj["text"]
    @channel = obj["channel"]["name"]
    @link = obj["permalink"]
    @timestamp = obj["ts"]
  end

  def to_mark_down()
    time = Time.at(@timestamp.to_i()).strftime("%T")
    "[#{time}](#{@link}): #{@text}"
  end

end

class MarkDown
  attr_reader

  def initialize(markdowned_arr)
    today = Date.today.strftime("/%Y/%m/%d")
    @title = today
    @category = "日報"
    @body = markdowned_arr.join("\n")
  end

  def post()
    client = Esa::Client.new(access_token: ESA_ACCESS_TOKEN, current_team: ESA_CURRENT_TEAM)
    client.create_post(name: @title, body_md: @body, category: @category, wip: false)
  end
end

def fetch_today_channel_message()
  today = Date.today.strftime("%Y-%m-%d")
  query = "on:" + today + " "
  client = Slack.client
  option = {
      :query => query,
  }
  res = client.search_messages(option)
end

json = fetch_today_channel_message()

hash_messages = json["messages"]["matches"].select{|k| k["type"] == "message" }


messages = []

hash_messages.each do |message|
  messages.push(Message.new(message))
end

markdonwed_messages = messages.select{|m| m.channel == SLACK_CHANNEL_NAME}.map{|m| m.to_mark_down()}.reverse()

esa_markdown = MarkDown.new(markdonwed_messages)

esa_markdown.post()
