# frozen_string_literal: true

source 'https://rubygems.org'
gemspec

if File.file? File.expand_path './.enable_dev', __dir__
  group :development do
    gem 'debug'
  end
end

if File.file? File.expand_path './.enable_test', __dir__
  group :development, :test do
    gem 'rubocop', require: false
    gem 'rubocop-performance', require: false
    gem 'test-unit', '~> 3.6.8'
  end
end
