# coding: utf-8
module Resque
  module Reports
  	module Encodings
  		def self.included(base)
  			base.class_eval do 
          CP1251 = 'w:windows1251'
          UTF8 = 'utf-8'
  			end
  		end  		
  	end
  end
end
