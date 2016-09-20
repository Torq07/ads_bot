module AdsCreator

	def initialize_ad
		new_ad=Ad.create(message:message.text, address:user.address)
		user.marketplace ? user.marketplace.ads<<new_ad : user.ads<<new_ad
		if user.phone
			request('Would you like to add picture to ad?',answers: ['yes','no'])
		else	
			text = 'Please provide your contact'
			button_text='Send contact'
		  MessageSender.new(bot: bot, chat: message.from, text: text, contact_request:button_text).send 
		end  

	end

	def save_ad  

		@ad.save
		text = "Thank you, your ad is now saved. It's ID is: #{@ad.id}"
		@answers=["Sell something","Latest ads","Frequently asked questions"]
	  MessageSender.new(bot: bot, chat: message.from, answers: @answers, text: text).send 
		rescue LongMessage
			text = 'This is not valid AD. Length is bigger than 140 characters'
		  MessageSender.new(bot: bot, chat: message.from, text: text).send if message.to_s.length >140

	end

	def check_ad_for_photo

		raise NoAd.new unless @ad && @ad.picture.nil?
		true
		rescue NoAd
			text = 'Sorry you don\'t create any ad for picture'
		  MessageSender.new(bot: bot, chat: message.from, text: text).send 
		  return false

	end


end