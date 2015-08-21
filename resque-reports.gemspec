# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'resque/reports/version'

Gem::Specification.new do |gem|
  gem.name          = 'resque-reports'
  gem.version       = Resque::Reports::VERSION
  gem.authors       = ['Sergey D.']
  gem.email         = ['sclinede@gmail.com']
  gem.description   = 'Make your custom reports to CSV in background using Resque with simple DSL'
  gem.summary       = 'resque-reports'
  gem.homepage      = 'https://github.com/sclinede/resque-reports'
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}) { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_dependency 'resque-integration', '~> 1.1.0'
  gem.add_dependency 'activesupport' # избавиться от зависимости

  gem.add_development_dependency 'bundler', '~> 1.3'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec', '>= 2.14.0'
  gem.add_development_dependency 'simplecov'
  gem.add_development_dependency 'timecop', '~> 0.7.1'
end
