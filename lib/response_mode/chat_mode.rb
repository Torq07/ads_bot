require './lib/message_sender'
Dir['./models/*'].each {|file| require file} 

class NoAd < StandardError ; end

class ChatMode

	attr_reader :message
  attr_reader :bot
  attr_reader :user
  attr_reader :answers

  def initialize(options)
    @bot = options[:bot]
    @message = options[:message]
    @user = options[:user]
    @@ad||=nil
		@answers=["Show more","Search again",
						 "Show contact","Show picture",
						 "Latest ads","Sell something"]
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
		when  'Please enter your ad text. Be sure to include a good description as well as a price. There is a 140 character limit. When you\'re done, press send and you can add a photo in the next step.'
			initialize_ad
		when "Please enter ID"
			show_picture if message.text[/\d+/i]
		when 'Please enter  ID'
			show_contact if message.text[/\d+/i]
		when 'Please enter what are you searching?'
			search_item(message.text) if message.text
		end	 
	end

	def manage_direct_messages
		case message.text 
    when '/start'
      answer_with_greeting_message
    when '/stop'
      answer_with_farewell_message
		when 'Search again'
			request_searching_item
    when /contact/i
    	request_id('  ')  
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
			request_id(' ')
		when /latest ads/i
			get_latest_ads
		when /new/
			test_functions	
		else
    	not_valid_request("Wrong command")
    end
	end

	def test_functions
		p user
		mp=user.creator.marketplaces.new
		mp.save
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
	
	def request_searching_item
		text="Please enter what are you searching?"
		MessageSender.new(bot: bot, chat: message.from, text: text, force_reply:true).send
	end

	def request_id(param)
		text="Please enter#{param}ID"
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
	
	def show_contact
		requested_user=Ad.find(message.text[/\d+/]).user if Ad.
		text="#{requested_user.fname} #{requested_user.lname}\n#{requested_user.phone}"
		MessageSender.new(bot: bot, chat: message.from, answers: @answers, text: text).send	
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
		text="Your location is saved, thank you. Gain is an powerful local ads bot to discover an sell great products around you. \n\nUse Gain with the following simple commands:\n\ntype 'search' to search\n\ntype 'sell' and wait for the prompt to sell.\n\nYou can also navigate using the buttons at the bottom of the screen.\n\nBy using Gain you agree to our terms & conditions: www.gain.im/terms.html"
  	MessageSender.new(bot: bot, chat: message.from, text: text).send
		@answers=['Show more','Sell something']
		puts 'works'
		get_latest_ads
	end	
	  
	def manage_contacts
		user.update_attributes(phone: message.contact.phone_number,
													 fname: message.contact.first_name,
													 lname: message.contact.last_name)
		add_picture_to_ad
	end
    
	def add_ads
		text='Please enter your ad text. Be sure to include a good description as well as a price. There is a 140 character limit. When you\'re done, press send and you can add a photo in the next step.'
  	MessageSender.new(bot: bot, chat: message.from, text: text, force_reply: true).send
	end

	def initialize_ad
		@@ad=user.ads.new(message:message.text, address:user.address)
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
			text = "Thank you, your ad is now saved. It's ID is: #{@@ad.id}"
			@answers=["Sell something","Latest ads","Frequently asked questions"]
		  MessageSender.new(bot: bot, chat: message.from, answers: @answers, text: text).send 
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
