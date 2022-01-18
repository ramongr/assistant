# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'assistant/version'

Gem::Specification.new do |spec|
  spec.name = 'assistant'
  spec.version = Assistant::VERSION
  spec.authors = ['Ramon Rodrigues']
  spec.email = ['cerberus.ramon@gmail.com']

  spec.summary = 'Simple, composable services'
  spec.description = 'Simple, composable services'
  spec.homepage = 'https://github.com/ramongr/assistant'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.5.0'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
    spec.metadata['changelog_uri'] = 'https://github.com/ramongr/assistant/blob/main/CODE_OF_CONDUCT.md'
    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = 'https://github.com/ramongr/assistant'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
          'public gem pushes.'
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'brakeman', '~> 5.2'
  spec.add_development_dependency 'bundler', '~> 2.3', '>= 2.3.5'
  spec.add_development_dependency 'fasterer', '~> 0.9.0'
  spec.add_development_dependency 'rake', '~> 13.0', '>= 13.0.6'
  spec.add_development_dependency 'rspec', '~> 3.10'
  spec.add_development_dependency 'rubocop', '~> 1.24', '>= 1.24.1'
  spec.add_development_dependency 'rubocop-faker', '~> 1.1'
  spec.add_development_dependency 'rubocop-performance', '~> 1.13', '>= 1.13.2'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.7'
end
