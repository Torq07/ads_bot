module AdsCreator

	def initialize_ad
		new_ad=Ad.create(message:message.text, address:user.address)
		user.marketplace ? user.marketplace.ads<<new_ad : user.ads<<new_ad
		if user.phone
			request(text:'Would you like to add picture to ad?',
							answers: ['yes','no'])
		else	
			request(text:'Please provide your contact', 
							contact_request:'Send contact' )
		end  

	end

	def save_ad  
		@ad.save
		answers=["Sell something","Latest ads","Frequently asked questions"]
		request(text:"Thank you, your ad is now saved. It's ID is: #{@ad.id}",
						answers:answers)

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