module AdsCreator

	def initialize_ad
		new_ad=Ad.create(message:message.text, address:user.address)
		user.marketplace ? user.marketplace.ads<<new_ad : user.ads<<new_ad
		if user.phone
			request('Would you like to add picture to ad?',answers: ['yes','no'])
		else	
			request('Please provide your contact', contact_request:'Send contact' )
		end  

	end

	def save_ad  

		request("Thank you, your ad is now saved. It's ID is: #{@ad.id}",
						answers:["Sell something","Latest ads","Frequently asked questions"])

		rescue LongMessage
			if message.to_s.length >140
				request('This is not valid AD. Length is bigger than 140 characters') 
			end	
	end

	def check_ad_for_photo

		raise NoAd.new unless @ad && @ad.picture.nil?
		true
		rescue NoAd
			request('Sorry you don\'t create any ad for picture')
		  return false

	end


end