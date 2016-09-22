require './lib/message_sender'
require './models/user'
require './lib/requests_handler'

class CallbackMode
	
	include RequestsHandler

	attr_reader :message
  attr_reader :bot
  attr_reader :user
  attr_reader :answers

  def initialize(options)
    @bot = options[:bot]
    @message = options[:message]
    @user = options[:user]
		@answers=["Show more","Search again",
						 "Show contact","Show picture",
						 "Latest ads","Sell something"]
  end
	 
  def response
	  case message.data
	    when /^(\d+)/i
        MessageSender.new(bot: bot, 
        									chat: message.from, 
        									answers:@answers, 
        									text: User.find($1.to_i).contacts
        									).send
      when /Show more search result/i 
        get_next_results 
      when /agreament_(.*)/
      	agreament($1)
      when /admin_(\d+)/
      	attribute = if user.superuser?  
      		user.update_attribute(:current_admin_marketplace_id, $1)
      		c = "request(text:\"Thank you! You have logged into \"+
					 \"administrative area\")"
      	else
      		user.update_attribute(:requested_marketplace_id, $1)
      		c = "request(text:'Please enter passphrase for this marketplace',
      					 force_reply: true)"	
      	end		
      	eval c
      when /logout/i
      	logout	
      when /moderate_(.*)/
      	moderate_($1)		
	  end
	end 

	def get_next_results
		text=user.results
						 .shift(3)
						 .map{ |res| "*ID:* _#{res[0]}_\n#{res[1]}"}
						 .join("\n\n")
		if text.length<2
			text,@answers="There are no ads which match your search."+
										"Type 'search' to search again or press the"+
										"'latest ads' button. Have something to sell?"+ 
										"Press the 'sell something' button to add it.",
										["Search again","Latest Ads","Sell something"]
		end								
		MessageSender.new(bot: bot,
										  chat: message.from,
										  answers: @answers,
										  text: text).send
		user.save
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

	def moderate_(attribute)
		photo=nil
		text=nil
		results=Marketplace.find(user.current_admin_marketplace_id)
			.ads.pluck(attribute.to_sym,:user_id,:id)
		results.each do |item|
			answers=[
						{text:'Delete', callback_data:"delete_ad_#{item[2]}"},
						{text:'Ban user', callback_data:"ban_user_#{item[1]}"}
							]	
			if attribute == 'message'
				request(text: item[0], inline: true, answers: answers)
			else
				request(photo: item[0], inline: true, answers: answers)
			end	
		end	
	end
	
end	
