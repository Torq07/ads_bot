require 'telegram/bot'
require './lib/app_configurator'
require './models/user'
require './models/ad'
require 'date'

config = AppConfigurator.new
config.configure

token = config.get_token
ads=Ad.where("DATE(expiration) = ?", Date.today)
Telegram::Bot::Client.run(token) do |bot|
	ads.each do |ad|
	 uid=User.find(ad.user_id).uid
	 bot.api.send_message(chat_id: uid, text: "Your AD with ID: #{ad.id} has bee expired")
	end
end
