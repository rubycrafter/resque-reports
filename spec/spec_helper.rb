# coding: utf-8
require 'simplecov'
SimpleCov.start

require 'rubygems'
require 'bundler/setup'
require 'rspec'
require 'timecop'

require 'resque-reports'

require 'mock_redis'
redis = MockRedis.new
Resque.redis = redis
