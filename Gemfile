source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.6.3'

gem "activesupport"

group :test do
  gem 'rspec', '~> 3.0'
  gem 'simplecov', require: false, group: :test
end

group :test, :development do
  gem 'pry', '~> 0.12.2'
end