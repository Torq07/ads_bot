require_relative 'main_requests'

module Marketplaces

	include MainRequests

	def create_marketplace
		user.creator.marketplaces.create(address:user.address)
		request(text:"Now give your marketplace a name", force_reply:true)
	end

	def check_for_marketplaces
		command = user.superuser? ? "Marketplace" : "user.marketplaces"
		markets=eval(command).all
										.pluck(:name, :id)
										.map{|m| {text:m[0], callback_data:"admin_#{m[1]}"} }
		hash = if markets.count>0
			{ 
				text:"Which marketplace would you like to admin?",
				inline: true, 
				answers: markets 
			}	
		else
			{
				text: "Sorry you don't have any created marketplaces",
				answers: @answers
			}
		end		

		request(hash)

	end

	def check_passphrase
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
		market=Marketplace.find(id)
		unless market.banned_id?(user.id)
  		user.update_attribute(:marketplace_id,id)	
  		text="You have joined #{name.to_hashtag}"
  	else
  		text="Sorry your account is banned in this particular marketplace"
  	end	
  	name = market.name.split.map(&:capitalize).join
  	check_place
  	request(text:text,answers: @answers)

	end

	def leave_mp
		
		hash = if user.marketplace_id
			name=Marketplace.find(user.marketplace_id).name
			user.update_attribute(:marketplace_id,nil)	
			check_place
			{text: "You have left marketplace #{name.to_hashtag}", answers: @answers}
		else
			{text: "Sorry you not in marketplace to leave it",answers: @answers}
		end	

		request(hash)

	end


	def markets
		markets=Marketplace.near( user.address, 50, :units => :km )
							.map{|m| {text:m[:name], callback_data:"join_#{m[:name]}_#{m[:id]}"} }
		hash = if markets.count>0
			{
				text:"Which marketplace would you like to enter?",
				inline: true, 
				answers: markets					
			}	
		else
			{
				text: "Sorry you don't have marketplaces around you",
				answers: @answers
			}
		end					
		request(hash)
	end

	def markets?
		hash = if user.marketplace_id
			market_name=Marketplace.find(user.marketplace_id).name
			{text:"You're in #{market_name} ", answers: @answers}
		else
			{text:"You're not entered in any market", answers: @answers}
		end	
		request(hash)
	end

	def delete_ad_from_marketplace(ad_id)
		Ad.find(ad_id).update_attribute(:marketplace_id,nil)
		request(text:'Ad was removed', answers: @answers)
	end

	def ban_user_in_markteplace(user_id)
		mt=Marketplace.find(user.current_admin_marketplace_id)
		mt.banned_id<<user_id unless mt.banned_id.include?(user_id)
		required_user=User.find(user_id)
		required_user.update_attribute( :marketplace_id, nil )
		mt.save
		request(text: "User #{user.contacts} was banned", answers: @answers)
	end

	def moderate
		existed_ads=Marketplace.find(user.current_admin_marketplace_id)
													 .ads
													 .count if user.current_admin_marketplace_id
		hash = if admin?(user) && existed_ads>0
			answers=[
				{text:'Text',callback_data:'moderate_message'},
				{text:'Photo',callback_data:'moderate_picture'}
							]
			{text:'What would you like to moderate?', inline: true, answers: answers}				
		elsif	admin?(user)
			{text:'Sorry your Marketplace don\'t have any ads', 
			 answers: @answers}				
		else	
			{text: "Sorry you're not an admin", answers: @answers}
		end	

		request(hash)
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
			text = item[0] ? item[0] : 'No text description'				
			if type == 'message'
				request(text: text, inline: true, answers: answers)
			else
				request(photo: text, inline: true, answers: answers)
			end	
		end	
	end

end