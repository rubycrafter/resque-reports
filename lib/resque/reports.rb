# coding: utf-8
require 'active_support'

require 'forwardable'
require 'facets/kernel/constant'

require 'resque-integration'

require 'resque/reports/version'
require 'resque/reports/cache_file'
require 'resque/reports/callbacks'
require 'resque/reports/encodings'
require 'resque/reports/base_report'
require 'resque/reports/csv_report'


module Resque
  module Reports
  	ActiveSupport::Dependencies.autoload_paths << "#{File.dirname(__FILE__)}../../app/jobs"
  end
end
