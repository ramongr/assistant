require "rubygems"
require "bundler"
require "rake"
require "rspec/core/rake_task"
require "standard/rake"

Bundler::GemHelper.install_tasks(name: "factory_bot")

desc "Default: run all specs and standard"
task default: %w[all_specs standard]

desc "Run all specs and features"
task all_specs: %w[spec:unit]

namespace :spec do
  desc "Run unit specs"
  RSpec::Core::RakeTask.new("unit") do |t|
    t.pattern = "spec/{*_spec.rb,assistant/**/*_spec.rb}"
  end
end
