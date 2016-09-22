module MarketplaceCreator

	def create_marketplace
		user.creator.marketplaces.create(address:user.address)
		request(text:"Now give your marketplace a name", force_reply:true)
	end

	def save_marketplace_name
		@marketplace.update_attribute(:name, message.text.strip)
		request(text:"And a short description –"+
 						"where are you? What will you sell? Why "+
 						"should people use your marketplace?",force_reply:true)
	end

	def save_marketplace_description
		@marketplace.update_attribute(:description, message.text.strip)
		request(text:'Enter passphrase which will be your'+
 						'password to this marketplace analytics',force_reply:true)
	end

	def save_marketplace_pass
		@marketplace.update_attribute(:pass, message.text.strip)
		agreament_request
	end

	def check_for_marketplaces
		command = user.superuser? ? "Marketplace" : "user.marketplaces"
		marketplaces=eval(command).all
										.pluck(:name, :id)
										.map{|m| {text:m[0], callback_data:"admin_#{m[1]}"} }
		request(text:"Which of marketplaces you would"+
 						"like to administrate?",inline: true, answers: marketplaces)
	end

	def check_passphrase
		answers=nil
		requested_marketplace=user.marketplaces
															.find(user.requested_marketplace_id)
		if requested_marketplace.pass == message.text.strip
			user.update_attributes(
			 current_admin_marketplace_id: user.requested_marketplace_id,
			 requested_marketplace_id: nil
			)
			text = "Thank you! You have logged into "+
					 	 "administrative area"
			answers = ['Analytics','Moderate','Logout']		 	 
		else
			text = 'Sorry your password is incorrect.'+
						 'Please remember that pass is case sensetive'	
		end	
			request(text:text,answers: answers)
	end

end