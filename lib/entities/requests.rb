require_relative 'main_requests'
require_relative 'search'

module Requests

	include MainRequests
	include Search
	
	def agregate_inline_answers(answers)
		answers.map do |answer|
			Telegram::Bot::Types::InlineKeyboardButton.new(answer)
		end	
	end

	def check_place
		if user.marketplace_id 
			@answers = @answers.reject{|a| a=="/Markets"}.push("/Leave market")
		else
			@answers = @answers.reject{|a| a=="/Leave market"}.push("/Markets")
		end	
	end

	def agreament(desicion)
		
		marketplace=user.creator.marketplaces.find_by(agreament: nil)

		text=if marketplace && desicion == 'true' 
			marketplace.update_attribute(:agreament, true)
			"Thank you, your marketplace is created"
		elsif marketplace 
			marketplace.destroy 
			"Your marketplace cannot be created if you do not agree"+
 			"with our terms, your request has been cancelled"
		end

		request(text:text, answers: @answers)	

	end

	def show_contact_by_ad_id

		text=Ad.includes(:user)
			.find(message.text[/\d+/].to_i)
			.user
			.contacts

		request(text: text, answers: @answers)	
		
		rescue 
			not_valid_request("There is no AD with this ID")	

	end	

	def show_contact_by_request_(id)
		request( text: User.find(id.to_i).contacts, answers:@answers )
	end

	def show_picture(id,answers=nil)
		required_ad=Ad.find(id)

		if required_ad.picture
			answers||=[
				{text: 'Show more',
				 callback_data: "Show more search result" }
							]
			request(inline: true, 
							photo: required_ad.picture,
							answers: answers )
		else
			text="There is no image for this ad"
			answers||=[
				{text:'Show more',
				 callback_data:"Show more search results"}
							]
			request(text: text, answers: answers, inline: true)
		end

		# rescue 
		#   not_valid_request("There is no AD with this ID")	

	end 

	def analytics
		text = if user.current_admin_marketplace_id
			mp=Marketplace.find(user.current_admin_marketplace_id)
			"Total number of ads: #{mp.ads.count},\n"+
		  "Total number of users: #{mp.users.count}"
		else
			"Sorry you're not admin"
		end	
		if user.superuser?
			text+=",\nTotal user marketplaces: #{Marketplace.all.count}"
		end	
		request(text:text)
	end

	def admin?(user_for_check=nil)
		if user_for_check
			user_for_check.current_admin_marketplace_id
		else
			if user.current_admin_marketplace_id
				answers = [{text:'Logout?',
					 callback_data:"logout"}]
				text = "Currently administrating #"+
				"#{Marketplace.find(user.current_admin_marketplace_id).name}"
				request(text:text, 
								inline: true,
								answers: answers)
			else
				request(text:'Nope')
			end	
		end	
	end

	def login_request(mp_id)
		attribute = if user.superuser?  
  		user.update_attribute(:current_admin_marketplace_id, mp_id)
  		hash={text:"Thank you! You have logged into "+
			 					"administrative area"}
  	else
  		user.update_attribute(:requested_marketplace_id, mp_id)
  		hash={text:'Please enter passphrase for this marketplace',
  					 force_reply: true}
  	end		
  	request(hash)
	end

	def logout
		hash = if user.current_admin_marketplace_id
			user.update_attribute( :current_admin_marketplace_id, nil )
			{text:'You\’ve signed out as an admin'}
		else
			{text:'You\'re not an admin to logout'}
		end	
		request(hash)
	end

	def help
		if user.current_admin_marketplace_id
			text = "Marketplace admin commands:"+
						"\n/admin - log in to marketplace"+
						"\n/admin? - check is currently logged as admin"+
						"\n/analytics - show marketplace analytics "+
						"\n/moderate - moderate marketplace"+
						"\n/logout – logout as admin "+
						"\n\nGeneral marketplace commands: "+
						"\n\/new - create and run your own marketplace"+
						"\n\/markets? – shows which marketplace you’re in "+
						"\n\/leave – leave the current marketplace"+
						"\n\n\/markets – shows marketplaces around you"+
						"\n\/join – join a marketplace"+
						"\n\nJust write a message to search"+
						"\n\n\/sell – list an item to sell"
		else	
			text = "\n\nUse Gain with these simple commands:"+
						 "Just write a message to search"+
						 "\n/sell – list an item to sell"+
						 "\n/markets – shows marketplaces around you"+
						 "\n/join – join a marketplace"+
						 "\n/new - create and run your own marketplace"+
						 "\n/markets? – shows which marketplace you’re in" 
						 "\n/leave – leave the current marketplace"+
						 "\nFor more help, join the Gain channel at"+
						 " www.telegram.me/gainim "
		end		 
		request(text: text, answers: @answers)
	end

end 