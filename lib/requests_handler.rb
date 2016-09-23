module RequestsHandler
	
	def request(opts={text:''})

		if opts[:inline]
			opts[:answers]=agregate_inline_answers(opts[:answers]) 
		end
			
		command,content = if opts[:photo] 
			 ['send_photo', "photo: \"#{opts[:photo]}\""]
			else
			 ['send', "text: \"#{opts[:text]}\""]
		end	
		 
		send_code=%Q{ MessageSender.new(bot: bot, 
			chat: message.from, 
			#{content}, 
			force_reply: opts[:force_reply], 
			answers: opts[:answers],
			inline: opts[:inline],
			contact_request: opts[:contact_request],
			location_request: opts[:location_request]).#{command} }
		eval send_code										

	end
	
	def agregate_inline_answers(answers)
		answers.map do |answer|
			Telegram::Bot::Types::InlineKeyboardButton.new(answer)
		end	
	end

	def not_valid_request(text="")
		request(text:"This is not valid request. #{text}")
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

	def get_next_results

		text=user.results   
						 .shift(3) 
						 .map{ |res| "*ID:* _#{res[0]}_\n #{res[1]}"}
						 .join("\n\n")
	  if text.length<2
			text = "There are no ads which match your search."+
 						 "Type 'search' to search again or press the"+
 						 "'latest ads' button. Have something to sell?"+
 						 "Press the 'sell something' button to add it."
			@answers = ["Search again","Latest Ads","Sell something"] 
		end	
		request(text:text,answers: @answers)
		user.save

	end	

	def get_latest_ads

		results=Ad.near( user.address, 50, :units => :km )
							.last(30)
							.to_a
							.map{ |res| [res.id,res.message] }
		user.update_attribute(:results,results)
		get_next_results

	end
	


	def show_contact

		text=Ad.includes(:user)
			.find(message.text[/\d+/].to_i)
			.user
			.contacts
		MessageSender.new(bot: bot,
			chat: message.from,
			answers: @answers, 
			text: text).send	
		rescue 
			not_valid_request("There is no AD with this ID")	

	end	

	def show_picture
		required_ad=Ad.find(message.text.to_i)
		if required_ad.picture
			answers=[
				{text: "Seller contact",
				 callback_data: required_ad.user_id},
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
				 callback_data: required_ad.user_id.to_s },
				{text:'Show more search results',
				 callback_data:"Show more search results"}
							]
			request(text, answers:answers, inline: true)
		end									
		rescue 
		  not_valid_request("There is no AD with this ID")	

	end 

	def search_item(searching_item)
		
		t=Ad.arel_table
		obj = user.marketplace ? user.marketplace.ads : Ad
		pattern="%#{searching_item.strip}%"
		results=obj.where( t[:message].matches( pattern ) )
			.near( user.address, 20, :units => :km )
			.map{ |res| [res.id,res.message] }
		user.update_attribute(:results,results)
		get_next_results
		
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

	def logout
		user.update_attribute( :current_admin_marketplace_id, nil )
		request(text:'You\'re sign out from administrative area')
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

	def join_marketplace
		markets=Marketplace.near( user.address, 50, :units => :km )
							.map{|m| {text:m[:name], callback_data:"join_#{m[:name]}_#{m[:id]}"} }
		request(text:"Which of marketplaces you would"+
 						"like to join?",inline: true, answers: markets)
	end

end 