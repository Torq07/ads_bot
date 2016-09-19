require 'active_record'
require 'geocoder'
require "geocoder/railtie"
Geocoder::Railtie.insert

class Marketplace < ActiveRecord::Base
	
	belongs_to :creator
	has_many :users
	has_many :ads
	# attr_accessor :latitude, :longitude
	geocoded_by :address   # can also be an IP address
	after_validation :geocode 	

end
