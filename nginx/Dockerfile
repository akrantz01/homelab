FROM debian:11 as build

ENV RUST_VERSION 1.66.0
ENV RUSTUP_VERSION 1.25.1

ENV NGINX_VERSION 1.22.1
ENV NGINX_FULL_VERSION ${NGINX_VERSION}-1~bullseye
ENV QUICHE_VERISON 0.16.0
ENV NJS_VERSION 0.7.9

RUN addgroup --system nginx && \
    adduser --system -D -h /var/cache/nginx -s /sbin/nologin -G nginx nginx

RUN set -eux && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y ca-certificates && \
    update-ca-certificates

# Install build dependencies
RUN apt-get install -y \
  autoconf \
  build-essential \
  cmake \
  curl \
  debian-archive-keyring \
  dpkg-dev \
  g++ \
  git \
  gnupg2 \
  libgd-dev \
  libgeoip-dev \
  liblmdb-dev \
  libmaxminddb-dev \
  libpcre3-dev \
  libperl-dev \
  libssl-dev \
  libtool \
  libxml2-dev \
  libxslt-dev \
  lsb-release \
  wget \
  zlib1g-dev

# Install Rust
ENV RUSTUP_HOME /usr/local/rustup
ENV CARGO_HOME /usr/local/cargo
ENV PATH $CARGO_HOME/bin:$PATH
RUN set -eux && \
    wget https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/x86_64-unknown-linux-gnu/rustup-init && \
    chmod +x rustup-init && \
    ./rustup-init -y --no-modify-path --profile minimal --default-toolchain ${RUST_VERSION} --default-host x86_64-unknown-linux-gnu && \
    rm rustup-init && \
    chmod -R a+w $RUSTUP_HOME $CARGO_HOME

WORKDIR /usr/src

# Download nginx source
RUN set -eux && \
    curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor -o /usr/share/keyrings/nginx-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/debian `lsb_release -cs` nginx" >> /etc/apt/sources.list.d/nginx.list && \
    echo "deb-src [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/debian `lsb_release -cs` nginx" >> /etc/apt/sources.list.d/nginx.list && \
    apt-get update && \
    apt-get source nginx=${NGINX_FULL_VERSION} && \
    rm -rf nginx_${NGINX_VERSION}* && \
    mv nginx-${NGINX_VERSION} nginx

# Download extra modules
RUN set -eux && \
    git clone --recursive https://github.com/google/ngx_brotli && \
    git clone --recursive https://github.com/openresty/headers-more-nginx-module.git && \
    git clone --recursive https://github.com/AirisX/nginx_cookie_flag_module.git

RUN set -eux && \
    git clone --recursive https://github.com/nginx/njs.git && \
    cd njs && \
    git checkout --recurse-submodules tags/${NJS_VERSION}

RUN set -eux && \
    git clone --recursive https://github.com/cloudflare/quiche.git && \
    cd quiche && \
    git checkout --recurse-submodules tags/${QUICHE_VERISON}

# Download nginx patches
RUN set -eux && \
    wget -q https://raw.githubusercontent.com/kn007/patch/master/Enable_BoringSSL_OCSP.patch && \
    wget -q https://raw.githubusercontent.com/kn007/patch/master/nginx_with_quic.patch

# Patch Nginx
RUN set -eux && \
    cd nginx && \
    patch -p1 < /usr/src/nginx_with_quic.patch && \
    patch -p1 < /usr/src/Enable_BoringSSL_OCSP.patch

# Modify debian build scripts
RUN set -eux && \
    sed -i 's/libpcre2-dev/libpcre3-dev/g' nginx/debian/control && \
    NGX_BROTLI_REF=$(git --git-dir=ngx_brotli/.git rev-parse --short HEAD) && \
    MORE_HEADERS_REF=$(git --git-dir=headers-more-nginx-module/.git rev-parse --short HEAD) && \
    COOKIE_FLAG_REF=$(git --git-dir=nginx_cookie_flag_module/.git rev-parse --short HEAD) && \
    CONFIG="\
        --build=\"nginx quiche-${QUICHE_VERISON} ngx_brotli-$NGX_BROTLI_REF more-headers-$MORE_HEADERS_REF njs-${NJS_VERSION} cookie_flag-$COOKIE_FLAG_REF\" \
        --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx \
        --modules-path=/usr/lib/nginx/modules \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/nginx.lock \
        --http-client-body-temp-path=/var/cache/nginx/client_temp \
        --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
        --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
        --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
        --user=nginx \
        --group=nginx \
        --with-pcre-jit \
        --with-http_ssl_module \
        --with-http_realip_module \
        --with-http_addition_module \
        --with-http_sub_module \
        --with-http_dav_module \
        --with-http_flv_module \
        --with-http_mp4_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_random_index_module \
        --with-http_secure_link_module \
        --with-http_stub_status_module \
        --with-http_auth_request_module \
        --with-http_xslt_module=dynamic \
        --with-http_image_filter_module=dynamic \
        --with-http_geoip_module=dynamic \
        --with-http_perl_module=dynamic \
        --with-threads \
        --with-stream \
        --with-stream_ssl_module \
        --with-stream_ssl_preread_module \
        --with-stream_realip_module \
        --with-stream_geoip_module=dynamic \
        --with-http_slice_module \
        --with-mail \
        --with-mail_ssl_module \
        --with-compat \
        --with-file-aio \
        --with-http_v2_module \
        --with-http_v2_hpack_enc \
        --with-http_v3_module \
        --with-openssl=/usr/src/quiche/quiche/deps/boringssl \
        --with-quiche=/usr/src/quiche \
        --add-module=/usr/src/ngx_brotli \
        --add-module=/usr/src/headers-more-nginx-module \
        --add-module=/usr/src/njs/nginx \
        --add-module=/usr/src/nginx_cookie_flag_module \
        --with-cc-opt=\"-Wno-error $\(CFLAGS\)\" \
        --with-ld-opt=\"$\(LDFLAGS\)\" \
        --with-select_module \
        --with-poll_module \
        " && \
        echo s#CFLAGS=\"\".*#CFLAGS=\"\" ./configure $CONFIG#1 > nginx-debian-rules.sed && \
        echo s#CFLAGS=\"\".*#CFLAGS=\"\" ./configure $CONFIG --with-debug#2 >> nginx-debian-rules.sed && \
        sed -i -f nginx-debian-rules.sed nginx/debian/rules && \
        apt-get build-dep -y nginx

# Build nginx
RUN set -eux && \
    cd nginx && \
    dpkg-buildpackage -b && \
    mv ../nginx_${NGINX_FULL_VERSION}_amd64.deb /nginx_amd64.deb
