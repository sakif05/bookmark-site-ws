require 'open-uri'
require 'uri'
require 'nokogiri'
require 'image_size'


class UrlFormatValidation < ActiveModel::Validator
	def validate(record)
		parts = URI.split(record.url)
		unless parts[0] and parts [2]
			record.errors[:url] = "Sorry, that URL wasn't recognized as valid."
		end
	end
end

class BookmarkUrl < ActiveRecord::Base
  attr_accessible :url, :embed
  before_save :check_thumbnails_and_embed
  serialize :thumbnail_urls
  has_many :user_bookmarks
  has_many :playlists, :through => :user_bookmarks

	before_validation :regularize_url
	include ActiveModel::Validations
	validates_with UrlFormatValidation

		def regularize_url
			parts = URI.split(self.url)
			if parts[0].nil?
				self.url = 'http://'+self.url
				#maybe this will be where I strip away some stuff, not sure
			end
		end

		def embed_domains
			@embed_domains ||= ['youtube.com','www.youtube.com','vimeo.com','www.vimeo.com']
		end

		def thumbnail_domains
			@thumbnail_domains ||= ['youtube.com','www.youtube.com','vimeo.com','www.vimeo.com']
		end

		def set_embed
			parts = URI.split(self.url)
			if (embed_domains.include? parts[2])
				case parts[2]
				when 'youtube.com','www.youtube.com'
					embed= "<iframe width=\"560\" height=\"315\" src=\"http://www.youtube.com/embed/REPLACEME\" frameborder=\"0\" allowfullscreen></iframe>"
					URI.decode_www_form(URI.split(url)[7..8].join()).each do |a|
						if a[0] == 'v'
							self.embed = embed.gsub(/REPLACEME/,a[1]).html_safe
						end
					end
				when 'vimeo.com','www.vimeo.com'
					embed = "<iframe src=\"http://player.vimeo.com/video/REPLACEME\" width=\"500\" height=\"281\" frameborder=\"0\" webkitAllowFullScreen mozallowfullscreen allowFullScreen></iframe>"
					self.embed = embed.gsub(/REPLACEME/, parts[5].match(/[0-9]+/)[0]).html_safe
				end
			end
			# return embedFinal
		end

		def set_thumbnails
			parts = URI.split(self.url)
			if (thumbnail_domains.include? parts[2])
				self.thumbnail_urls = {};
				case parts[2]
				when 'youtube.com', 'www.youtube.com'
					id = nil
					URI.decode_www_form(URI.split(url)[7..8].join()).each do |a|
						if a[0] == 'v'
							id = a[1]
						end
					end
					if id
						self.thumbnail_urls['thumbindex'] = 1
						self.thumbnail_urls['thumbindexstart'] = 1
						self.thumbnail_urls['numthumbs']= 3
						(1..3).each do |i|
							self.thumbnail_urls['thumb'+i.to_s] = "http://img.youtube.com/vi/" +id.to_s+'/'+i.to_s+'.jpg'
						end
					end
				when 'vimeo.com', 'www.vimeo.com'
					self.thumbnail_urls['thumbindex'] = 1
					self.thumbnail_urls['thumbindexstart'] = 1
					self.thumbnail_urls['numthumbs']= 1
					response = Nokogiri::XML(open("http://vimeo.com/api/v2/video/"+parts[5].match(/[0-9]+/)[0]+".xml"))
					self.thumbnail_urls['thumb1'] = response.css('thumbnail_medium').children.text
				end
			end
		end

		def check_thumbnails_and_embed
			if self.embed.nil?
				self.set_embed
			end
			if self.thumbnail_urls.nil?
				self.set_thumbnails
			end
		end

end