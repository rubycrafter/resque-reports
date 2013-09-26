# coding: utf-8
module Resque
  module Reports
  	module Encodings
      module ClassConstants
        CP1251 = 'w:windows1251'
        UTF8 = 'utf-8'
      end
  		def self.included(base)
  			extend ClassConstants
  		end  		
  	end
  end
end
