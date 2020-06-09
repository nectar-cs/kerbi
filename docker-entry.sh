#!/bin/bash

if [[ "$1" == "test" ]]; then
  bundle exec rspec -fd
#  ls
#  echo 'in cov'
#  ls coverage
#  bash <(curl -s https://codecov.io/bash) -s /app/coverage
elif [[ "$1" == "publish" ]]; then
  mkdir /root/.gem
  echo ":rubygems_api_key: $RUBYGEMS_API_KEY" > /root/.gem/credentials
  chmod 0600 /root/.gem/credentials
  gem build kerbi.gemspec
  gem push $(ls | grep ".gem$"); exit 0
else
  echo "Bad args $@"
fi