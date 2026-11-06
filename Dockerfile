FROM docker.io/library/ruby:4.0.9-slim-trixie AS builder
WORKDIR /root
COPY Gemfile /root/
COPY Gemfile.lock /root/
# TODO: Remove rubyzip override once license_finder allows rubyzip >= 3.4.0 (CVE-2026-85396)
# hadolint ignore=DL3008
RUN apt-get update \
  && apt-get -y --no-install-recommends install build-essential \
  && rm -rf /var/lib/apt/lists/* \
  && BUNDLE_PATH=/opt/lf_bundle bundle install \
  && gem_dir=/opt/lf_bundle/ruby/$(ruby -e 'puts RbConfig::CONFIG["ruby_version"]') \
  && gem install --install-dir "$gem_dir" --no-document rubyzip -v 3.7.0 \
  && gem uninstall --install-dir "$gem_dir" --ignore-dependencies rubyzip -v 2.4.1 \
  && sed -i 's/%q<rubyzip>.freeze, \[">= 1".freeze, "< 3".freeze\]/%q<rubyzip>.freeze, [">= 3.4.0".freeze, "< 4".freeze]/' "$gem_dir"/specifications/license_finder-*.gemspec \
  && grep -F -q '%q<rubyzip>.freeze, [">= 3.4.0".freeze, "< 4".freeze]' "$gem_dir"/specifications/license_finder-*.gemspec \
  && rm -rf /root/.bundle/cache \
  && rm -rf /opt/lf_bundle/cache/*.gem \
  && find /opt/lf_bundle/ruby/*/gems/ -regex ".*\.[cho]" -delete

FROM docker.io/library/ruby:4.0.9-slim-trixie
# TODO: Remove json cleanup once base image includes json >= 2.19.9 (CVE-2026-33210, CVE-2026-54696)
# TODO: Remove package upgrades once base image includes apt and libapt-pkg7.0 >= 3.0.4 (CVE-2026-109518)
# hadolint ignore=DL3008
RUN apt-get update \
  && apt-get -y --no-install-recommends --only-upgrade install apt libapt-pkg7.0 \
  && rm -rf /var/lib/apt/lists/* \
  && rm -f /usr/local/lib/ruby/gems/*/specifications/default/json-*.gemspec \
  && ruby_lib=$(ruby -e 'puts RbConfig::CONFIG["rubylibdir"]') \
  && ruby_arch=$(ruby -e 'puts RbConfig::CONFIG["rubyarchdir"]') \
  && rm -r "$ruby_lib/json.rb" "$ruby_lib/json" "$ruby_arch/json"
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
