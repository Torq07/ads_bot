Dir['./models/*'].each {|file| require file} 
Dir['./lib/entities/*'].each {|file| require file} 

class CallbackMode
	
	include Requests
	include Marketplaces
	include Ads

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
	    when /contact_(\d+)/i
	    	show_contact_by_request_($1)
      when /Show more search result/i 
        get_next_results 
      when /agreament_(.*)/
      	agreament($1)
      when /admin_(\d+)/
      	login_request($1)
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
	
end	
