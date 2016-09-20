module MarketplaceCreator

	def create_marketplace
		user.creator.marketplaces.create(address:user.address)
		request("Now give your marketplace a name", force_reply:true)
	end

	def save_marketplace_name
		@marketplace.update_attribute(:name, message.text.strip)
		request("And a short description – where are you? What will you sell? Why should people use your marketplace?",force_reply:true)
	end

	def save_marketplace_description
		@marketplace.update_attribute(:description, message.text.strip)
		request('Enter passphrase which will be your password to this marketplace analytics',force_reply:true)
	end

	def save_marketplace_pass
		@marketplace.update_attribute(:pass, message.text.strip)
		agreament_request
	end

	def check_for_marketplaces
		marketplaces=user.creator.marketplaces.all
		# request('Whi')
	end

end