class ReplyMarkupFormatter
  attr_reader :array

  def initialize(array)
    @array = array
  end

  def get_markup
    Telegram::Bot::Types::ReplyKeyboardMarkup
      .new(keyboard: array.each_slice(2).to_a, one_time_keyboard: true, resize_keyboard: true)
  end

  def get_inline_markup
  	Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: array.each_slice(2).to_a)
  end

  def get_contact_request(button_text)
    kb = Telegram::Bot::Types::KeyboardButton.new(text: button_text, 
                                                  request_contact: true)                                           
    Telegram::Bot::Types::ReplyKeyboardMarkup
      .new(keyboard: kb, one_time_keyboard: true, resize_keyboard: true)     
  end  
  
  def get_location_request(button_text)
    kb = Telegram::Bot::Types::KeyboardButton.new(text: button_text, 
                                                  request_location: true)
    Telegram::Bot::Types::ReplyKeyboardMarkup
      .new(keyboard: kb, one_time_keyboard: true, resize_keyboard: true)     
  end 

  def get_force_reply
    Telegram::Bot::Types::ForceReply.new(force_reply: true)      
  end  
    
end
