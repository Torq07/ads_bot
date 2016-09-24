require_relative 'main_requests'

module Search

	include MainRequests

	def search_item(searching_item)
		
		t=Ad.arel_table
		obj = user.marketplace ? user.marketplace.ads : Ad
		pattern="%#{searching_item.strip}%"
		
		results=obj.where( t[:message].matches( pattern ) )
			.near( user.address, 20, :units => :km )
			.map{ |res| [res.id,res.message] }
		user.update_attribute(:results,results)
		
		get_next_results
		
	end

	def get_next_results

		text=user.results   
						 .shift(3) 
						 .map{ |res| "*ID:* _#{res[0]}_\n #{res[1]}"}
						 .join("\n\n")
	  if text.length<2
			text = "There are no ads which match your search."+
 						 "Type 'search' to search again or press the"+
 						 "'latest ads' button. Have something to sell?"+
 						 "Press the 'sell something' button to add it."
			@answers = ["Search again","Latest Ads","Sell something"] 
		end	
		
		request(text:text,answers: @answers)
		user.save

	end	

	def get_latest_ads

		obj = user.marketplace ? user.marketplace.ads : Ad
		results=obj.near( user.address, 50, :units => :km )
							.last(30)
							.to_a
							.map{ |res| [res.id,res.message] }
		user.update_attribute(:results,results)
		get_next_results

	end

end