require 'active_record'
require 'geocoder'
require "geocoder/railtie"
Geocoder::Railtie.insert

class LongMessage < StandardError ; end

class Ad < ActiveRecord::Base
	
	belongs_to :user
	belongs_to :marketplace
	before_create :set_expiration_date , :check_length
	# attr_accessor :latitude, :longitude
	geocoded_by :address   # can also be an IP address
	after_validation :geocode 	

	def set_expiration_date
	  self.expiration =  Date.today + 30.days
	end
	
	def check_length
		raise LongMessage.new if self.message.length>140	
	end

end
