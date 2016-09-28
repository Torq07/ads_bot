module MainRequests

	def request(opts={text:''})
		if opts[:inline]
			opts[:answers]=agregate_inline_answers(opts[:answers]) 
		end
			
		command,content = if opts[:photo] 
			 ['send_photo', "photo: \"#{opts[:photo]}\""]
			else
			 ['send', "text: \"#{opts[:text]}\""]
		end	
		 
		send_code=%Q{ MessageSender.new(bot: bot, 
			chat: message.from, 
			#{content}, 
			force_reply: opts[:force_reply], 
			answers: opts[:answers],
			inline: opts[:inline],
			contact_request: opts[:contact_request],
			location_request: opts[:location_request]).#{command} }
	
		eval send_code										

	end

	def not_valid_request(text="")
		request(text:"That’s not a valid command. #{text}")
	end

	def save_(hash)
		hash[:value]||=message.text.strip
		hash[:instance].update_attribute(hash[:attribute], hash[:value])		
		request(hash[:r_hash]) if hash[:r_hash]
	end
	
end	
