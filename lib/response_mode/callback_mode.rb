require './lib/message_sender'
require './models/user'
require './models/ad'
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
      when /join_(.*)_(\d+)/
      	join_marketplace($1,$2)
      	
      when /logout/i
      	logout	
      when /moderate_(.*)/
      	moderate_($1)		
      when /delete_ad_(\d+)/
      	delete_ad_from_marketplace($1)
      when /ban_user_(.*)/
      	ban_user_in_markteplace($1)
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
	
	def join_marketplace(name,id)
		Marketplace.find(id).banned_id?(user.id)
		unless Marketplace.find(id).banned_id?(user.id)
  		user.update_attribute(:marketplace_id,id)	
  		text="You enter to #{name} marketplace"
  	else
  		text="Sorry your account is banned in this particular marketplace"
  	end	
  	request(text:text,answers: @answers)
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

end	
