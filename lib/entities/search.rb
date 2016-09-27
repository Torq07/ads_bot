require_relative 'main_requests'
require 'json'

module Search

	include MainRequests

	def search_item(searching_item)
		
		t=Ad.arel_table
		obj = user.marketplace ? user.marketplace.ads : Ad
		pattern="%#{searching_item.strip}%"
		
		results=obj.where( t[:message].matches( pattern ) )
			.near( user.address, 20, :units => :km )
			.map{ |res| [res.id, res.message, res.user_id] }
		user.update_attribute(:results,results)
		
		get_next_results
		
	end

	def get_next_results
		
		response_hash={}

		results=user.results.shift(3).map do |ad| 
			{
				text:"*ID:* _#{ad[0]}_\n #{ad[1]}",
				answers: [
					{text:"Show contact",callback_data: "contact_#{ad[2]}" },
					{text:"Show picture",callback_data: "picture_#{ad[0]}" }
				],
				inline: true
			}
		end	
		 
	  if results.count>0
	  	results.each do |result|
				request(result)
	  	end
	  else	
			response_hash[:text] = "There are no ads which match your search."+
 						 "Type 'search' to search again or press the"+
 						 "'latest ads' button. Have something to sell?"+
 						 "Press the 'sell something' button to add it."
		  @answers = ["/Search","/Latest Ads","/Sell something"] 
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
			.map{ |res| [res.id, res.message, res.user_id]}
		user.update_attribute(:results,results)
		get_next_results

	end

end