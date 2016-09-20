require './lib/message_sender'
require './models/user'

class CallbackMode
	
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
	    when /(\d+)/i
        MessageSender.new(bot: bot, 
        									chat: message.from, 
        									answers:@answers, 
        									text: User.find($1.to_i).contacts
        									).send
      when /Show more search result/i 
        get_next_results 
      when /agreament_(.*)/
      	agreament($1)
	  end
	end 

	def get_next_results
		text=user.results
						 .shift(3)
						 .map{ |res| "*ID:* _#{res[0]}_\n#{res[1]}"}
						 .join("\n\n")
		text,@answers="There are no ads which match your search. Type 'search' to search again or press the 'latest ads' button. Have something to sell? Press the 'sell something' button to add it.",["Search again","Latest Ads","Sell something"] if text.length<2
		MessageSender.new(bot: bot, chat: message.from, answers: @answers, text: text).send
		user.save
	end	

	def agreament(desicion)

		text=if desicion == 'true' 
			user.creator.marketplaces.find_by(agreament: nil).update_attribute(:agreament, true)
			"Thank you, your marketplace is created"
		else
			user.creator.marketplaces.find_by(agreament: nil)
			"Your marketplace cannot be created if you do not agree with our terms, your request has been cancelled"
		end
			
		MessageSender.new(bot: bot, chat: message.from, answers: @answers, text: text).send

	end
	
end	
