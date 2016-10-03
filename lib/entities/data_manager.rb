require_relative 'main_requests'
require './lib/file_uploader'

module DataManager

	include MainRequests

	def manage_photos

		if check_ad_for_photo
			@ad.picture=message.photo.last.file_id
			save_ad
		end	

  end

  def manage_documents
  	
   #  FileUploader.new(bot:bot)
			# .load(message.document.file_id,message.document.file_name)

  end
  
	def manage_locations(longitude,latitude)
		user.update_attributes(longitude: longitude, latitude: latitude)
		request(text:'Please provide your contact', 
			contact_request:'Send contact',
			answers: ['Send contact manually'] )
	end	
	  
	def manage_contacts
		user.update_attributes(phone: message.contact.phone_number,
			fname: message.contact.first_name,
			lname: message.contact.last_name)
		help("All saved, thank you. Gain is your local marketplace.")
	end

end