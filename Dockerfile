FROM debian:13-slim AS builder
WORKDIR /usr/src

RUN apt-get update \
    && apt-get install -yqq --no-install-suggests --no-install-recommends \
        build-essential \
        git \
        curl \
        ca-certificates \
        libpcre2-dev \
        zlib1g-dev \
        libssl-dev \
        libgeoip-dev \
        libxml2-dev \
        libxslt1-dev \
    && rm -rf /var/lib/apt/lists/*

RUN curl -s "https://nginx.org/download/$(curl -s http://nginx.org/en/download.html | grep -oE '/nginx-[0-9].*.tar.gz' | sed 's/ /\n/g' | grep -oE 'nginx-.*.tar.gz' | uniq | sed -n '2p')" | tar -xz && \
    cd nginx-* && \
    git clone https://github.com/vozlt/nginx-module-vts.git && \
    cd nginx-module-vts && git checkout $(git describe --tags --abbrev=0) && cd .. && \
    ./configure --user=nginx --group=nginx \
        --sbin-path=/usr/sbin/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --pid-path=/run/nginx.pid \
        --lock-path=/run/lock/subsys/nginx \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --with-select_module \
        --with-poll_module \
        --with-threads \
        --with-file-aio \
        --with-http_ssl_module \
        --with-http_v2_module \
        --with-http_v3_module \
        --with-http_realip_module \
        --with-http_geoip_module \
        --with-http_sub_module \
        --with-http_dav_module \
        --with-http_mp4_module \
        --with-http_slice_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_auth_request_module \
        --with-http_secure_link_module \
        --with-http_stub_status_module \
        --with-stream \
        --with-stream_ssl_module \
        --with-stream_realip_module \
        --with-stream_geoip_module \
        --with-stream_ssl_preread_module \
        --with-cc-opt='-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -fPIC' \
        --with-ld-opt='-Wl,-z,relro -Wl,-z,now -Wl,-as-needed' \
        --add-module=nginx-module-vts && \
    make -j$(nproc) && make install


FROM debian:13-slim

# Install runtime dependencies (including ca-certificates for SSL/TLS validation)
RUN apt-get update && \
    apt-get install -yqq --no-install-suggests --no-install-recommends \
        ca-certificates \
        libssl3 \
        libpcre2-8-0 \
        libgeoip1 \
        zlib1g \
        openssl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean all

COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=builder /etc/nginx /etc/nginx
COPY --from=builder /var/log/nginx /var/log/nginx

RUN useradd -r -s /sbin/nologin nginx && \
    mkdir -p /var/log/nginx /usr/local/nginx/client_body_temp /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx /usr/local/nginx /etc/nginx

EXPOSE 80 443

CMD ["/usr/sbin/nginx"]
