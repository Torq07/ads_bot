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
		value = user.marketplace_id ? "Leave marketplace" : "Marketplaces"
		@answers[6] = value
	end

	def agreament_request
		text="In order to finish, please read the Terms & Conditions"+
 				 "for the Gain Marketplace Bot"+
 				 "[www.gain.im/terms](http://www.gain.im/terms) and press agree."
		answers=[
						{text:"Agree", callback_data: 'agreament_true'},
	 					{text:'Disagree', callback_data: 'agreament_false'}
	 					]
		request(text:text, answers: answers, inline: true)
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

	def show_picture
		required_ad=Ad.find(message.text.to_i)

		if required_ad.picture
			answers=[
				{text: "Seller contact",
				 callback_data: "contact_#{required_ad.user_id}"},
				{text: 'Show more',
				 callback_data: "Show more search result" }
							]
			request(inline: true, 
							photo: required_ad.picture,
							answers: answers )
		else
			text="There is no image for this ad"
			answers=[
				{text:"Request seller contact",
				 callback_data: "contact_#{required_ad.user_id}" },
				{text:'Show more search results',
				 callback_data:"Show more search results"}
							]
			request(text: text, answers:answers, inline: true)
		end

		rescue 
		  not_valid_request("There is no AD with this ID")	

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

	def admin?
		if user.current_admin_marketplace_id
			answers = [{text:'Logout?',
				 callback_data:"logout"}]
			text = "Currently administrating marketplace "+
			"#{Marketplace.find(user.current_admin_marketplace_id).name}"
			request(text:text, 
							inline: true,
							answers: answers)
		else
			request(text:'Nope')
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
		user.update_attribute( :current_admin_marketplace_id, nil )
		request(text:'You\'re sign out from administrative area')
	end

end 