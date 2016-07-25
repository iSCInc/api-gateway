FROM reutersmedia/openresty-luarocks:1.9.7.4

WORKDIR /gateway
RUN wget https://releases.hashicorp.com/consul-template/0.14.0/consul-template_0.14.0_linux_amd64.zip -O /tmp/consul.zip \
 && unzip /tmp/consul.zip -d /usr/local/bin && rm /tmp/consul.zip
RUN apk --no-cache --update add --virtual build-deps make gcc linux-headers musl-dev perl-dev
COPY api_gateway-0.1-0.rockspec ./
RUN /opt/openresty/luajit/bin/luarocks install api_gateway-0.1-0.rockspec
RUN PERL_MM_USE_DEFAULT=1 perl -MCPAN -e 'install Test::Nginx::Socket'
RUN mkdir /opt/openresty/nginx/logs
EXPOSE 8100
ENV PATH $PATH:/opt/openresty/luajit/bin 
COPY ./ ./

