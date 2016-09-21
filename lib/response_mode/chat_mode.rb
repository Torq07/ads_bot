require './lib/message_sender'
require './lib/marketplace_creator'
require './lib/requests_handler'
require './lib/data_manager'
require './lib/ads_creator'
Dir['./models/*'].each {|file| require file} 

class NoAd < StandardError ; end

class ChatMode

	include MarketplaceCreator
	include RequestsHandler
	include DataManager
	include AdsCreator

	attr_reader :message, :bot, :user, :answers
	attr_accessor :ad

  def initialize(options)
    @bot = options[:bot]
    @message = options[:message]
    @user = options[:user]
    @ad=user.ads.last || nil
    @marketplace=user.creator.marketplaces.last || nil 
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
		when  /Please enter your ad text/
			initialize_ad
		when "Please enter ID"
			show_picture if message.text[/\d+/i]
		when 'Please enter  ID'
			show_contact if message.text[/\d+/i]
		when 'Please enter what are you searching?'
			search_item(message.text) if message.text
		when 'Now give your marketplace a name'
			save_marketplace_name
		when /And a short description/
			save_marketplace_description
		when /^Enter passphrase/
			save_marketplace_pass	
		when 'Please enter passphrase for this marketplace'
			check_passphrase	
		end	 
	end

	def manage_direct_messages
		case message.text 
    when '/start'
    	request(I18n.t('greeting_message'),location_request: 'Send location')
    when '/stop'
    	request(I18n.t('farewell_message'))
      answer_with_farewell_message
		when 'Search again'
			request("Please enter what are you searching?", force_reply:true)
    when /contact/i
    	request("Please enter\s\sID", force_reply:true)  
    when /\Asell/i 
    	request('Please enter your ad text. Be sure to include a good description as well as a price. There is a 140 character limit. When you\'re done, press send and you can add a photo in the next step.',force_reply:true)
    when /\Ano/i
    	save_ad
    when /\byes\b/i
    	request('Please upload picture for this ad')
    when /\Asearch(.*)/i
    	search_item($1)
    when /more/i
			get_next_results
		when /show picture/i
			request("Please enter\sID",force_reply:true)
		when /latest ads/i
			get_latest_ads
		when /\/new/i
			create_marketplace
		when '/admin'
			check_for_marketplaces
		when /\/logout_admin/i
			user.update_attribute( :current_admin_marketplace_id, nil )
		when '/admin?'
			admin?	
		else
    	not_valid_request("Wrong command")
    end
	end

end	
