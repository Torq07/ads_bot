module RequestsHandler
	
	def request(text,opts={})

		MessageSender.new(bot: bot, 
											chat: message.from, 
											text: text, 
											force_reply: opts[:force_reply], 
											answers: opts[:answers] ).send

	end
	
	def not_valid_request(text="")

		text="This is not valid request. #{text}"
		MessageSender.new(bot: bot, chat: message.from, text: text).send

	end

	def answer_with_greeting_message

	  text = I18n.t('greeting_message')
	  button_text='Send Location'
	  MessageSender.new(bot: bot, chat: message.from, text: text, location_request: button_text).send

	end

	def answer_with_farewell_message

	  text = I18n.t('farewell_message')
	  MessageSender.new(bot: bot, chat: message.from, text: text).send

	end


	def agreament_request

		text="In order to finish, please read the Terms & Conditions for the Gain Marketplace Bot [www.gain.im/terms](http://www.gain.im/terms) and press agree."
		answers=[
			Telegram::Bot::Types::InlineKeyboardButton.new(
				text:"Agree", 
				callback_data: 'agreament_true'),
			Telegram::Bot::Types::InlineKeyboardButton.new(
				text:'Disagree', 
				callback_data: 'agreament_false')
						]
		MessageSender.new(bot: bot, 
											chat: message.from,
											text: text, 
											answers: answers, 
											inline: true
											).send

	end

	def get_next_results

		text=user.results   
						 .shift(3) 
						 .map{ |res| "*ID:* _#{res[0]}_\n #{res[1]}"}
						 .join("\n\n")
		text,@answers="There are no ads which match your search. Type 'search' to search again or press the 'latest ads' button. Have something to sell? Press the 'sell something' button to add it.",["Search again","Latest Ads","Sell something"] if text.length<2
		MessageSender.new(bot: bot, chat: message.from, answers: @answers, text: text).send
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
			MessageSender.new(bot: bot, 
											chat: message.from, 
											photo:required_ad.picture, 
											answers: 
												[
												 Telegram::Bot::Types::InlineKeyboardButton.new(
													text:"Seller contact", 
													callback_data:required_ad.user_id),
												 Telegram::Bot::Types::InlineKeyboardButton.new(
													text:'Show more', 
													callback_data:"Show more search result")
												],
											inline: true)
											.send_photo
		else
			text="There is no image for this ad"
			MessageSender.new(bot: bot,
												chat: message.from, 
												text: text,
												answers: 
													[
													 Telegram::Bot::Types::InlineKeyboardButton.new(
														text:"Request seller contact \u1F4F1", 
														callback_data:required_ad.user_id),
													 Telegram::Bot::Types::InlineKeyboardButton.new(
														text:'Show more search results', 
														callback_data:"Show more search results")
													], 
												inline: true)
												.send	
		end									
		rescue 
		  not_valid_request("There is no AD with this ID")	

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