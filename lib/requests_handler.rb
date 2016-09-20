module RequestsHandler
	
	def request(text='',opts={})

		opts[:answers]=agregate_inline_answers(opts[:answers]) if opts[:inline]

		command,content = if opts[:photo] 
			 ['send_photo', "photo: \"#{opts[:photo]}\""]
			else
			 ['send', "text: \"#{text}\""]
		end	
		 
		send_code=%Q{ MessageSender.new(bot: bot, 
											chat: message.from, 
											#{content}, 
											force_reply: opts[:force_reply], 
											answers: opts[:answers],
											inline: opts[:inline],
											contact_request: opts[:contact_request],
											location_request: opts[:location_request]).#{command} if text}
		eval send_code										

	end
	
	def agregate_inline_answers(answers)
		answers.map do |answer|
			Telegram::Bot::Types::InlineKeyboardButton.new(answer)
		end	
	end

	def not_valid_request(text="")
		request("This is not valid request. #{text}")
	end

	def agreament_request
		text="In order to finish, please read the Terms & Conditions\
 for the Gain Marketplace Bot\
 [www.gain.im/terms](http://www.gain.im/terms) and press agree."
		answers=[
						{text:"Agree", callback_data: 'agreament_true'},
	 					{text:'Disagree', callback_data: 'agreament_false'}
	 					]
		request(text, answers: answers, inline: true)
	end

	def get_next_results

		text=user.results   
						 .shift(3) 
						 .map{ |res| "*ID:* _#{res[0]}_\n #{res[1]}"}
						 .join("\n\n")
	  if text.length<2
			text = "There are no ads which match your search.\
 Type 'search' to search again or press the\
 'latest ads' button. Have something to sell?\
 Press the 'sell something' button to add it."
			@answers = ["Search again","Latest Ads","Sell something"] 
		end	
		request(text,answers: @answers)
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

		text=Ad.includes(:user).find(message.text[/\d+/].to_i).user.contacts
		MessageSender.new(bot: bot, chat: message.from, answers: @answers, text: text).send	
		rescue 
			not_valid_request("There is no AD with this ID")	

	end	

	def show_picture
		required_ad=Ad.find(message.text.to_i)
		if required_ad.picture
			answers=[
				{text: "Seller contact", callback_data: required_ad.user_id},
				{text: 'Show more', callback_data: "Show more search result" }
							]
			request('',inline: true, 
								 photo: required_ad.picture,
								 answers: answers )
		else
			text="There is no image for this ad"
			answers=[
				{text:"Request seller contact",callback_data: required_ad.user_id.to_s },
				{text:'Show more search results',callback_data:"Show more search results"}
							]
			request(text, answers:answers, inline: true)
		end									
		# rescue 
		#   not_valid_request("There is no AD with this ID")	

	end 

	def search_item(searching_item)
		
		t=Ad.arel_table
		obj = user.marketplace ? user.marketplace.ads : Ad

		results=obj.where( t[:message].matches("%#{searching_item.strip}%") )
							.near( user.address, 20, :units => :km )
							.map{ |res| [res.id,res.message] }
		user.update_attribute(:results,results)
		get_next_results
		
	end

end 