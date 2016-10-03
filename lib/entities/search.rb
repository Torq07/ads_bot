require_relative 'main_requests'
require 'json'

module Search

	include MainRequests

	def search_item(searching_phrase)
		
		t=Ad.arel_table
		obj = user.marketplace ? user.marketplace.ads : Ad
		texts=searching_phrase.split.map(&:downcase)
		results=[]

		pattern="%#{texts.shift.strip}%"
		
		results=obj.where( t[:message].matches( pattern ) )
			.near( user.address, 20, :units => :km )
			.map{ |res| [res.id, 
									 res.message, 
									 res.user_id, 
									 res.marketplace_id] }
		texts.each do |searching_item|
			results = results.select {|r| r[1].downcase.include?(searching_item)}
		end									 
		
		user.update_attribute(:results,results)
		
		get_next_results
		
	end

	def get_next_results
		
		response_hash={}

		results=user.results.shift(3).map do |ad| 
			text = if ad[3]
				market_name=Marketplace.find(ad[3].to_i)
															 .name
				"#{ad[1]} #{market_name.to_hashtag}"
			else
				"#{ad[1]}"
			end


			if user.photo_setting
				[
				 ad[0],
				 {text: text},
				 [{text:"Show contact",callback_data: "contact_#{ad[2]}" }]
				]
			else	
				[
					{
						text: text,
						answers: [
							{text:"Show contact",callback_data: "contact_#{ad[2]}" },
							{text:"Show picture",callback_data: "picture_#{ad[0]}" }
						],
						inline: true
					}	
				]
			end
		end	
		 
	  if results.count>0
	  	results.each do |result|
	  		if user.photo_setting
	  			request(result[1])
	  			show_picture(result[0],result[2]) 
	  		else
	  			request(result[0])
	  		end	
	  	end
	  else	
			response_hash[:text] = "There are no ads which match your search."+
 						 "Type 'search' to search again or press the"+
 						 "'latest ads' button. Have something to sell?"+
 						 "Press the 'sell something' button to add it."
		  @answers = ["Latest Ads","Sell"] 
		  check_place
			response_hash[:answers] = @answers
			request(response_hash)
		end	
		
		user.save

	end	

	def get_latest_ads
		obj = user.marketplace ? user.marketplace.ads : Ad
		results=obj.near( user.address, 50, :units => :km )
			.last(30)
			.to_a
			.map{ |res| [res.id, res.message, res.user_id, res.marketplace_id]}
		user.update_attribute(:results,results)
		get_next_results

	end

	def photo_setting
		user.toggle!(:photo_setting)
		request(text: "Show photo: #{user.photo_setting}")
	end

end