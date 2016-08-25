require './lib/message_sender'
require './models/ad'

class NoAd < StandardError ; end

class ChatMode

	attr_reader :message
  attr_reader :bot
  attr_reader :user

  def initialize(options)
    @bot = options[:bot]
    @message = options[:message]
    @user = options[:user]
    @@ad||=nil
  end

  def response

	  if message.reply_to_message
	  	manage_replies
	  elsif	message.text
  		manage_direct_messages
	  elsif message.document
	  	manage_documents
	  elsif message.photo.first
	  	manage_photos	
	  elsif message.location
	  	manage_locations
	  elsif message.contact	
	  	manage_contacts
	  end

	end

	def manage_replies
		case message.reply_to_message.text
		when 'Please enter ad message.Max 140 chars'
			initialize_ad
		when 'Please enter AD-ID'
			show_picture if message.text[/\d+/i]
		end	
	end

	def manage_direct_messages
		case message.text
    when '/start'
      answer_with_greeting_message
    when '/stop'
      answer_with_farewell_message
    when /contacts?/i
    	get_contacts  
    when /\Asell/i
    	add_ads	
    when /\Ano/i
    	save_ad
    when /\byes\b/i
    	request_picture	
    when /\Asearch(.*)/i
    	search_item($1)
    when /more/i
			get_next_results
		when /show picture/i
			request_picture_id		
		when /latest ads/i
			get_latest_ads	
    else
    	not_valid_request("Wrong command")
    end
	end

	def get_next_results
		text=user.results
						 .shift(3)
						 .map{ |res| "*AD-ID:* _#{res[0]}_\n*AD-BODY:* _#{res[1]}_"}
						 .join("\n\n")
		answers=["More","Show picture"]
		text,answers="Sorry there is no more results",["Latest Ads"] if text.length<2
		MessageSender.new(bot: bot, chat: message.from, answers: answers, text: text).send
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

	def request_picture_id
		text="Please enter AD-ID"
		MessageSender.new(bot: bot, chat: message.from, text: text, force_reply:true).send
	end

	def not_valid_request(text="")
		text="This is not valid request. #{text}"
		MessageSender.new(bot: bot, chat: message.from, text: text).send
	end

	def show_picture
		message.text
		required_ad=Ad.find(message.text.to_i) 
		if required_ad.picture
			MessageSender.new(bot: bot, 
											chat: message.from, 
											photo:required_ad.picture, 
											answers: 
												[
												 Telegram::Bot::Types::InlineKeyboardButton.new(
													text:"Request seller contact \u1F4F1", 
													callback_data:required_ad.user_id),
												 Telegram::Bot::Types::InlineKeyboardButton.new(
													text:'Show more search results', 
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
		request=searching_item.strip
		t=Ad.arel_table
		results=Ad.where( t[:message].matches("%#{request}%") )
							.near( user.address, 20, :units => :km )
							.to_a
							.map{ |res| [res.id,res.message] }
		user.update_attribute(:results,results)
		get_next_results
	end

	def manage_photos
		if check_ad
			@@ad.picture=message.photo.last.file_id
			save_ad
		end	
  end

  def manage_documents
    FileUploader.new(bot:bot).load(message.document.file_id,message.document.file_name)
  end
  
	def manage_locations
		user.longitude=message.location.longitude
  	user.latitude=message.location.latitude
  	user.save
		text='Thank you, your location saved. Here are available command'
  	MessageSender.new(bot: bot, chat: message.from, text: text).send
	end	
	  
	def manage_contacts
		user.update_attributes(phone: message.contact.phone_number,
													 fname: message.contact.first_name,
													 lname: message.contact.last_name)
		add_picture_to_ad
	end
    
	def add_ads
		text='Please enter ad message.Max 140 chars'
  	MessageSender.new(bot: bot, chat: message.from, text: text, force_reply: true).send
	end

	def initialize_ad
		@@ad=user.ad.new(message:message.text, address:user.address)
		if user.phone
			add_picture_to_ad
		else	
			text = 'Please provide your contact'
			button_text='Send contact'
		  MessageSender.new(bot: bot, chat: message.from, text: text, contact_request:button_text).send 
		end  
	end

	def add_picture_to_ad
		text = 'Would you like to add picture to ad?'
	  MessageSender.new(bot: bot, chat: message.from, text: text, answers: ['yes','no']).send 
	end

	def request_picture
		text = 'Please upload picture for this ad'
	  MessageSender.new(bot: bot, chat: message.from, text: text).send 
	end
	
	def save_ad  
		if check_ad
			@@ad.save
			text = "Thank you your ads is saved. AD-ID :#{@@ad.id}"
		  MessageSender.new(bot: bot, chat: message.from, text: text).send 
		end	  
		rescue LongMessage
			text = 'This is not valid AD. Length is bigger than 140 characters'
		  MessageSender.new(bot: bot, chat: message.from, text: text).send if message.to_s.length >140
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

	def check_ad
		raise NoAd.new if @@ad.nil?
		true
		rescue NoAd
			text = 'Sorry you don\'t create any ad for picture'
		  MessageSender.new(bot: bot, chat: message.from, text: text).send 
		  return false
	end

end	