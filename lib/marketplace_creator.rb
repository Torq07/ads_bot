module MarketplaceCreator

	def create_marketplace
		user.creator.marketplaces.create(address:user.address)
		request("Now give your marketplace a name")
	end

	def save_marketplace_name
		@marketplace.update_attribute(:name, message.text.strip)
		request("And a short description – where are you? What will you sell? Why should people use your marketplace?")
	end

	def save_marketplace_description
		@marketplace.update_attribute(:description, message.text.strip)
		request('Enter passphrase which will be your password to this marketplace analytics')
	end

	def save_marketplace_pass
		@marketplace.update_attribute(:pass, message.text.strip)
		agreament_request
	end

end