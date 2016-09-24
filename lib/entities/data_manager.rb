require_relative 'main_requests'

module DataManager

	include MainRequests

	def manage_photos

		if check_ad_for_photo
			@ad.picture=message.photo.last.file_id
			save_ad
		end	

  end

  def manage_documents
  	
    FileUploader.new(bot:bot)
			.load(message.document.file_id,message.document.file_name)

  end
  
	def manage_locations(longitude,latitude)
		user.update_attributes(longitude: longitude, latitude: latitude)
		text="Your location is saved, thank you. Gain is and powerful"+
				 " local ads bot to discover an sell great products around you."+
				 " \n\nUse Gain with the following simple commands:"+
				 "\n\ntype 'search' to search\n\ntype 'sell'"+
				 " and wait for the prompt to sell.\n\nYou can also"+
				 " navigate using the buttons at the bottom of the screen."+
				 "\n\nBy using Gain you agree to our terms & conditions:"+
				 " www.gain.im/terms.html"+
				 "\n\n Your location set to: #{user.address}"
		# @answers=['Show more','Sell something']
		request(text: text)		
		request(text:'Please provide your contact', 
			contact_request:'Send contact',
			answers: ['Send contact manually'] )
	end	
	  
	def manage_contacts
		user.update_attributes(phone: message.contact.phone_number,
			fname: message.contact.first_name,
			lname: message.contact.last_name)
		request(text: 'Thank you. Your contact is saved', answers: @answers)
	end

end