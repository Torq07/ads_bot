require 'active_record'
require 'geocoder'
require 'geocoder/railtie'
Geocoder::Railtie.insert

class User < ActiveRecord::Base

	attr_accessor :latitude, :longitude
	has_many :ad, dependent: :destroy
  reverse_geocoded_by :latitude, :longitude
	after_validation :reverse_geocode
	
end
