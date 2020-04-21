FROM ruby:2.6.3-alpine3.10

WORKDIR /app

ARG TAG_NAME
ARG RUBYGEMS_API_KEY

ENV CRED_DIR /root/.gem
ENV CRED_PATH "$CRED_DIR/credentials"

RUN mkdir "$CRED_DIR"
RUN echo ":rubygems_api_key: $RUBYGEMS_API_KEY" > "$CRED_PATH"
RUN chmod 0600 "$CRED_PATH"

RUN apk --update add build-base libxslt-dev libxml2-dev

ADD Gemfile Gemfile.lock ./

RUN gem install bundler && \
     bundle config set without 'development test' && \
     bundle install --jobs 20 --retry 5

ADD . ./

RUN gem build kerbi.gemspec
RUN gem push $(ls | grep ".gem$")