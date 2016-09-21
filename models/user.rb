require 'active_record'
require 'geocoder'
require 'geocoder/railtie'
require './models/creator'

Geocoder::Railtie.insert

class User < ActiveRecord::Base

	attr_accessor :latitude, :longitude
	belongs_to :marketplace
	has_many :ads, dependent: :destroy
	has_one :creator, dependent: :destroy
	has_many :marketplaces, through: :creator, source: :marketplaces
  reverse_geocoded_by :latitude, :longitude
	after_validation :reverse_geocode
	after_create :relative_creator
	
	def relative_creator
		Creator.create(user_id: self.id)
	end

	def contacts

		"#{self.fname} #{self.lname}\n#{self.phone}"		

	end

end
