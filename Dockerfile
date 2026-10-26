FROM docker.io/library/ruby:4.0.8-slim-trixie AS builder
WORKDIR /root
COPY Gemfile /root/
COPY Gemfile.lock /root/
# hadolint ignore=DL3008
RUN apt-get update \
  && apt-get -y --no-install-recommends install build-essential \
  && rm -rf /var/lib/apt/lists/* \
  && BUNDLE_PATH=/opt/lf_bundle bundle install \
  && rm -rf /root/.bundle/cache \
  && rm -rf /opt/lf_bundle/cache/*.gem \
  && find /opt/lf_bundle/ruby/*/gems/ -regex ".*\.[cho]" -delete

FROM docker.io/library/ruby:4.0.8-slim-trixie
COPY --from=builder /opt/lf_bundle /opt/lf_bundle
RUN ruby_abi=$(ruby -e 'puts RbConfig::CONFIG["ruby_version"]') \
  && echo "GEM_PATH=/opt/lf_bundle/ruby/$ruby_abi:/usr/local/bundle" >>/etc/environment \
  && ln -s "/opt/lf_bundle/ruby/$ruby_abi" /opt/lf_bundle/current
ENV GEM_PATH=/opt/lf_bundle/current:/usr/local/bundle
ENV PATH=/opt/lf_bundle/current/bin:$PATH
WORKDIR /scan
VOLUME /scan
# nobody:nogroup
USER 65534:65534
ENV HOME=/tmp
ARG SOURCE_COMMIT
LABEL org.opencontainers.image.revision=$SOURCE_COMMIT
ENTRYPOINT ["license_finder"]
