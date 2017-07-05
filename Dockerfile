FROM alpine:3.6 AS build-env

ENV NGINX_MRUBY_VERSION a0450a03b06bdcbc311a1306c5e13291bc0bc6da
ENV NGINX_CONFIG_OPT_ENV '--with-ld-opt="-static" --prefix=/usr/local/nginx --with-http_stub_status_module --with-stream --without-stream_access_module'
ENV DOCKER_CHANNEL stable
ENV DOCKER_VERSION 17.03.1-ce

RUN apk add --no-cache wget ruby-rake git gcc make tar bison openssl-dev pcre-dev libc-dev
RUN mkdir -p /usr/local/src

WORKDIR /usr/loca/src

RUN wget https://github.com/matsumotory/ngx_mruby/archive/$NGINX_MRUBY_VERSION.tar.gz -O ngx_mruby.tar.gz
RUN mkdir ngx_mruby
RUN	tar --extract --file ngx_mruby.tar.gz --strip-components 1 --directory ngx_mruby

WORKDIR /usr/loca/src/ngx_mruby

COPY build_config.rb .
COPY mrbgem mrbgem
RUN sh build.sh
RUN make install
RUN wget -O /tmp/docker.tgz "https://download.docker.com/linux/static/${DOCKER_CHANNEL}/x86_64/docker-${DOCKER_VERSION}.tgz"
RUN tar --extract --file /tmp/docker.tgz --strip-components 1 --directory /usr/bin

FROM busybox

RUN mkdir -p /usr/local/nginx/logs

COPY --from=build-env /usr/local/nginx/sbin/nginx /usr/bin/nginx
COPY --from=build-env /usr/bin/docker /usr/bin/docker
COPY hook /usr/local/nginx/hook
COPY conf /usr/local/nginx/conf

CMD ["/usr/bin/nginx"]
