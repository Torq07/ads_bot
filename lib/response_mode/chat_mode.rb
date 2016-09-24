require './lib/message_sender'
Dir['./models/*'].each {|file| require file} 
Dir['./lib/entities/*'].each {|file| require file} 

class NoAd < StandardError ; end

class ChatMode

	include Marketplaces
	include Requests
	include DataManager
	include Ads

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
		check_place
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
	  	manage_locations(message.location.longitude,
	  		message.location.latitude)
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
			show_contact_by_ad_id if message.text[/\d+/i]
		when 'Please enter what are you searching?'
			search_item(message.text) if message.text
		when 'Now give your marketplace a name'
			next_step="And a short description –"+
				"where are you? What will you sell? Why "+
				"should people use your marketplace?"
			save_(instance:@marketplace, 
				attribute: :name, 
				r_hash: { text:next_step,
					force_reply: true}
					 )
		when /And a short description/
			next_step='Enter passphrase which will be your'+
 						'password to this marketplace analytics'
			save_(instance:@marketplace, 
				attribute: :description, 
				r_hash: { text:next_step,
					force_reply: true}
					 )
		when /^Enter passphrase/
			next_step="In order to finish, please read the Terms & Conditions"+
 				 "for the Gain Marketplace Bot"+
 				 "[www.gain.im/terms](http://www.gain.im/terms) and press agree."
 			answers=[
						{text:"Agree", callback_data: 'agreament_true'},
	 					{text:'Disagree', callback_data: 'agreament_false'}
	 					]	 
			save_(instance:@marketplace, 
				attribute: :pass, 
				r_hash: { text:next_step,
					answers: answers, 
					inline: true}
					 )
		when 'Please enter passphrase for this marketplace'
			check_passphrase
		when 'Please enter your first name'
			next_step='Please enter your lastname'		
			save_(instance:@user, 
				attribute: :fname, 
				r_hash: { text:next_step,
					force_reply: true}
					 )
		when 'Please enter your lastname'
			next_step='Please enter your phone number'	
			save_(instance:@user, 
				attribute: :lname, 
				r_hash: { text:next_step,
					force_reply: true}
					 )
		when 'Please enter your phone number'	
			next_step = 'Thank you. Your contact is saved'
			save_(instance:@user, 
				attribute: :phone, 
				r_hash: { text:next_step,
					force_reply: true,
					answers: @answers}
					 )
		when	/latlong/i
			if message.text && message.text[/\((.*)\,(.*)\)/] 
				manage_locations($2.to_f,$1.to_f) 
			end	
		end	 
	end

	def manage_direct_messages
		case message.text 
    when '/start'
    	request(text:I18n.t('greeting_message'),
    					location_request: 'Send location',
    					answers: ['Send location manually'])
    when 'Send location manually'
    	MessageSender.new(bot: bot, 
			chat: message.from, 
			document: 'BQADAgADcQADTCzCAhcacdBHjkfpAg'
			).send_document
    	request( text: 'Please [enter](http://www.latlong.net) your'+
    	 							' LatLong in this format'+
    	 							' (latitude,longitude) like in example above',
	 						 force_reply: true)	
    when '/stop'
    	request(text:I18n.t('farewell_message'))
      answer_with_farewell_message
		when 'Search again'
			request(text:"Please enter what are you searching?", 
				force_reply:true)
		when 'Send contact manually'
			request(text:"Please enter your first name",
				force_reply: true)		
    when /^contact/i
    	request(text:"Please enter\s\sID", force_reply:true)  
    when /\Asell/i
    	text='Please enter your ad text. Be sure to include'+
    			 'a good description as well as a price. '+
    			 'There is a 140 character limit.'+
    			 ' When you\'re done, press send and you can add '+
    			 'a photo in the next step.' 
    	request(text:text,force_reply:true)
    when /\Ano/i
    	save_ad
    when /\byes\b/i
    	request(text:'Please upload picture for this ad')
    when /\Asearch(.*)/i
    	search_item($1)
    when /more/i
			get_next_results
		when /show picture/i
			request(text:"Please enter\sID",force_reply:true)
		when /latest ads/i
			get_latest_ads
		when /\/new/i
			create_marketplace
		when '/admin'
			check_for_marketplaces
		when /analytics/i
			analytics	
		when /logout/i
			logout
		when /leave/i
			leave_mp
		when /moderate/i
			moderate	
		when /^marketplaces/i
			marketplaces_around
		when '/admin?'
			admin?
		else
    	not_valid_request("Wrong command")
    end
	end

end	
