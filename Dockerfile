FROM public.ecr.aws/docker/library/ruby:4.0.3-slim-trixie
WORKDIR /root
COPY Gemfile /root/
COPY Gemfile.lock /root/
RUN bundle config set --local path /opt/lf_bundle \
  && bundle install \
  && rm -rf /root/.bundle/cache \
  && rm -rf /opt/lf_bundle/cache/*.gem
RUN ruby_abi=$(ruby -e 'puts RbConfig::CONFIG["ruby_version"]') \
  && echo "GEM_PATH=/opt/lf_bundle/ruby/$ruby_abi:/usr/local/bundle" >>/etc/environment \
  && ln -s "/opt/lf_bundle/ruby/$ruby_abi" /opt/lf_bundle/current
ENV GEM_PATH=/opt/lf_bundle/current:/usr/local/bundle
ENV PATH=/opt/lf_bundle/current/bin:$PATH
WORKDIR /scan
VOLUME /scan
USER nobody:nogroup
ENV HOME=/tmp
ENTRYPOINT ["license_finder"]
