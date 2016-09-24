require './lib/message_sender'
Dir['./models/*'].each {|file| require file} 
Dir['./lib/entities/*'].each {|file| require file} 

class InlineMode

	attr_reader :message
  attr_reader :bot
  attr_reader :user

  def initialize(options)
    @bot = options[:bot]
    @message = options[:message]
    @user = options[:user]
  end
	 
	def response
	 	case message.query
	    when /start/i
	  end
 	end 

end	