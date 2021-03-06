require './lib/message_sender'
Dir['./models/*'].each {|file| require file} 
Dir['./lib/entities/*'].each {|file| require file} 
Dir['./lib/response_mode/*'].each {|file| require file} 

class MessageResponder
  
  attr_reader :message
  attr_reader :bot
  attr_reader :user

  def initialize(options)
    @bot = options[:bot]
    @message = options[:message]
    @user = User.find_or_create_by(uid: message.from.id)
  end

  def respond
    case message
      when Telegram::Bot::Types::InlineQuery
        # Here you can handle your inline commands
        InlineMode.new(message: message ,bot: bot, user: user).response
      when Telegram::Bot::Types::CallbackQuery
        # Here you can handle your callbacks from inline buttons
        CallbackMode.new(message: message ,bot: bot, user: user).response
      when Telegram::Bot::Types::Message   
        # Here you can handle your requests from chat
        ChatMode.new(message: message ,bot: bot, user: user).response
    end    
  end

end
