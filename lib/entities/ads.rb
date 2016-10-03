require_relative 'main_requests'

module Ads

	include MainRequests

	def initialize_ad
		new_ad=user.ads.create(message:message.text, address:user.address)
		user.marketplace ? user.marketplace.ads<<new_ad : user.ads<<new_ad
		request(text:'Do you want to add a photo?',
							answers: ['yes','no']) 

	end

	def no_text_for_ad
		request(text: "Please describe what you’re selling with words :) next you’ll add a photo.",
						force_reply: true)
	end

	def save_ad  
		if @ad
			@ad.save 
			answers=["Sell","Latest ads","Help"]
			request(text:"Thank you, your ad is now saved. It's ID is: #{@ad.id}",
							answers:answers)
		end	
		rescue LongMessage
			if message.to_s.length >140
				request(text:'This is not valid AD.'+
 								'Length is bigger than 140 characters') 
			end	
	end

	def check_ad_for_photo

		raise NoAd.new unless @ad && @ad.picture.nil?
		true
		rescue NoAd
			request(text:'Sorry you don\'t create any ad for picture')
		  return false

	end


end