require 'active_record'
require 'geocoder'
require "geocoder/railtie"
require './models/marketplace'

Geocoder::Railtie.insert

class Creator < ActiveRecord::Base
	
	belongs_to :user
	has_many :marketplaces, dependent: :destroy

end
