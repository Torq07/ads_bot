require './lib/message_sender'
require './models/user'

class CallbackMode
	
	attr_reader :message
  attr_reader :bot
  attr_reader :user

  def initialize(options)
    @bot = options[:bot]
    @message = options[:message]
    @user = options[:user]
  end
	 
  def response
	  case message.data
	    when /\d/i
        requested_user=User.find(message.data.to_i)
        text="#{requested_user.fname} #{requested_user.lname}\n#{requested_user.phone}"
        MessageSender.new(bot: bot, chat: message.from, text: text).send
      when /Show more search result/i 
        get_next_results 
	  end
	end 

  def get_next_results
    text=user.results.shift(3).map{ |res| "*AD-ID:* _#{res[0]}_\n*AD-BODY:* _#{res[1]}_"}.join("\n\n")
    text="Sorry there is no more results" if text.length<2
    MessageSender.new(bot: bot, chat: message.from, answers:['More','Random Ads','Show picture'],text: text).send
    user.save
  end 

end	