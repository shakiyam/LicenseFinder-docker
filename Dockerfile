FROM public.ecr.aws/docker/library/ruby:4.0.1-slim-trixie AS builder
WORKDIR /root
COPY Gemfile /root/
COPY Gemfile.lock /root/
# hadolint ignore=DL3008
RUN apt-get update \
  && apt-get -y install --no-install-recommends build-essential git \
  && rm -rf /var/lib/apt/lists/* \
  && bundle install \
  && rm -rf /root/.bundle/cache \
  && rm -rf /usr/local/bundle/cache/*.gem \
  && find /usr/local/bundle/gems/ -regex ".*\.[cho]" -delete

FROM public.ecr.aws/docker/library/ruby:4.0.1-slim-trixie
COPY --from=builder /usr/local/bundle /usr/local/bundle
# hadolint ignore=DL3008
RUN apt-get update \
  && apt-get -y install --no-install-recommends git \
  && rm -rf /var/lib/apt/lists/*
WORKDIR /scan
VOLUME /scan
USER nobody:nogroup
ENV HOME=/tmp
ENTRYPOINT ["license_finder"]
