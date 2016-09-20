module DataManager

	def manage_photos

		if check_ad_for_photo
			@ad.picture=message.photo.last.file_id
			save_ad
		end	

  end

  def manage_documents

    FileUploader.new(bot:bot).load(message.document.file_id,message.document.file_name)

  end
  
	def manage_locations

		user.longitude=message.location.longitude
  	user.latitude=message.location.latitude
  	user.save
		text="Your location is saved, thank you. Gain is an powerful local ads bot to discover an sell great products around you. \n\nUse Gain with the following simple commands:\n\ntype 'search' to search\n\ntype 'sell' and wait for the prompt to sell.\n\nYou can also navigate using the buttons at the bottom of the screen.\n\nBy using Gain you agree to our terms & conditions: www.gain.im/terms.html"
  	MessageSender.new(bot: bot, chat: message.from, text: text).send
		@answers=['Show more','Sell something']
		get_latest_ads

	end	
	  
	def manage_contacts

		user.update_attributes(phone: message.contact.phone_number,
													 fname: message.contact.first_name,
													 lname: message.contact.last_name)
		add_picture_to_ad
		
	end

end