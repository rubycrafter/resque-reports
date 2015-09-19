# coding: utf-8
require 'forwardable'
require 'resque-integration'
require 'attr_extras'

require 'resque/reports/services'
require 'resque/reports/patches'

require 'resque/reports/cache_file'
require 'resque/reports/base_report'
require 'resque/reports/csv_report'
require 'resque/reports/cache_file'
require 'resque/reports/config'

require 'resque/reports/version'


# Resque namespace
module Resque
  # Resque::Reports namespace
  module Reports
    CP1251 = 'cp1251'.freeze
    UTF8 = 'utf-8'.freeze
  end
end
