# coding: utf-8
Core.init_plugin do
  ActiveSupport::Dependencies.autoload_paths << "#{File.dirname(__FILE__)}/app/jobs"
end
