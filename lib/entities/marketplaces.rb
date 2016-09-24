require_relative 'main_requests'

module Marketplaces

	include MainRequests

	

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
		request(text:"Which of marketplaces you would "+
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
			@answers = ['Analytics','Moderate','Logout']		 	 
		else
			text = 'Sorry your password is incorrect.'+
						 'Please remember that pass is case sensetive'	
		end	
			request(text:text,answers: @answers)
	end

	def join_marketplace(name,id)
		
		Marketplace.find(id).banned_id?(user.id)
		unless Marketplace.find(id).banned_id?(user.id)
  		user.update_attribute(:marketplace_id,id)	
  		text="You enter to #{name} marketplace"
  	else
  		text="Sorry your account is banned in this particular marketplace"
  	end	
  	check_place
  	request(text:text,answers: @answers)

	end

	def leave_mp
		user.update_attribute(:marketplace_id,nil)	
		check_place
		request(text: 'You have left marketplace', answers: @answers)
	end


	def marketplaces_around
		markets=Marketplace.near( user.address, 50, :units => :km )
							.map{|m| {text:m[:name], callback_data:"join_#{m[:name]}_#{m[:id]}"} }
		request(text:"Which of marketplaces you would"+
 						"like to enter?",inline: true, answers: markets)
	end

	def delete_ad_from_marketplace(ad_id)
		Ad.find(ad_id).update_attribute(:marketplace_id,nil)
	end

	def ban_user_in_markteplace(user_id)
		mt=Marketplace.find(user.current_admin_marketplace_id)
		mt.banned_id<<user_id unless mt.banned_id.include?(user_id)
		User.find(user_id).update_attribute( :marketplace_id, nil )
		mt.save
	end

	def moderate
		answers=[
			{text:'Text',callback_data:'moderate_message'},
			{text:'Photo',callback_data:'moderate_picture'}
						]
		request(text:'What will be moderate?',
			inline: true,
			answers: answers)
	end

	def moderate_(type)
		photo=nil
		text=nil
		results=Marketplace.find(user.current_admin_marketplace_id)
			.ads.pluck(type.to_sym,:user_id,:id)
		results.each do |item|
			answers=[
						{text:'Delete', callback_data:"delete_ad_#{item[2]}"},
						{text:'Ban user', callback_data:"ban_user_#{item[1]}"}
							]	
			if type == 'message'
				request(text: item[0], inline: true, answers: answers)
			else
				request(photo: item[0], inline: true, answers: answers)
			end	
		end	
	end

end