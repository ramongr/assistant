# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'assistant/version'

Gem::Specification.new do |spec|
  raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.' unless spec.respond_to?(:metadata)

  spec.name = 'assistant'
  spec.version = Assistant::VERSION
  spec.authors = ['Ramon Rodrigues']
  spec.email = ['cerberus.ramon@gmail.com']

  spec.summary = 'Simple, soft fail enabled, composable services'
  spec.description = 'Simple, composable services'
  spec.homepage = 'https://github.com/ramongr/assistant'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.2'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['changelog_uri'] = 'https://github.com/ramongr/assistant/blob/main/CODE_OF_CONDUCT.md'
  spec.metadata['homepage_uri'] = 'https://github.com/ramongr/assistant'
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.metadata['source_code_uri'] = 'https://github.com/ramongr/assistant'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.require_paths = 'lib'

  spec.add_development_dependency 'brakeman', '~> 5.4', '>= 5.4.1'
  spec.add_development_dependency 'bundler', '~> 2.4', '>= 2.4.13'
  spec.add_development_dependency 'byebug', '~> 11.1', '>= 11.1.3'
  spec.add_development_dependency 'colorize', '~> 0.8.1'
  spec.add_development_dependency 'factory_bot', '~> 6.3'
  spec.add_development_dependency 'fasterer', '~> 0.10.1'
  spec.add_development_dependency 'rake', '~> 13.0', '>= 13.0.6'
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'rspec-collection_matchers', '~> 1.2'
  spec.add_development_dependency 'rspec_junit_formatter', '~> 0.6.0'
  spec.add_development_dependency 'rubocop', '~> 1.56.2'
  spec.add_development_dependency 'rubocop-faker', '~> 1.1'
  spec.add_development_dependency 'rubocop-performance', '~> 1.19'
  spec.add_development_dependency 'rubocop-rake', '~> 0.6.0'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.23.2'
end
