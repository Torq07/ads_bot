require './lib/app_configurator'

class FileUploader
	attr_reader :bot
	attr_reader :token

	def initialize(options)
    @bot = options[:bot]
    @token = AppConfigurator.new.get_token
    @logger = AppConfigurator.new.get_logger
  end

	def load(file_id,name)
		file_path=bot.api.getFile(file_id: file_id)["result"]["file_path"]
		open("./files/#{name}", 'wb') do |file|
			path="https://api.telegram.org/file/bot#{token}/#{file_path}"
		  file << open(path).read
		end
	end
end	