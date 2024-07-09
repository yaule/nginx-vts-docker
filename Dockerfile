FROM debian:bookworm-slim AS builder
WORKDIR /usr/src

RUN apt-get update \
    && apt-get install -yqq --no-install-suggests --no-install-recommends \
                patch make wget mercurial devscripts debhelper dpkg-dev \
                quilt lsb-release build-essential libxml2-utils xsltproc \
                equivs git g++ libparse-recdescent-perl \
    build-essential \
    libpcre3-dev \
    zlib1g-dev \
    libssl-dev \
    wget \
    curl \
    libpcre3 \
    zlib1g \
    libgeoip-dev libcurl4-openssl-dev libjansson-dev && \
    rm -rf /var/lib/apt/lists/*

RUN curl -s "https://nginx.org/download/$(curl -s http://nginx.org/en/download.html | grep -oE '/nginx-[0-9].*.tar.gz' | sed 's/ /\n/g' | grep -oE 'nginx-.*.tar.gz' | uniq | sed -n '2p')" | tar -xz && \
    cd nginx-* && \
    git clone https://github.com/vozlt/nginx-module-vts.git && \
    ./configure --user=nginx  --group=nginx \
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
    --with-http_slice_module \
    --with-http_stub_status_module \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_realip_module \
    --with-stream_geoip_module \
    --with-stream_ssl_preread_module \
    --add-module=nginx-module-vts && \
    make && make install


FROM debian:bookworm-slim

COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=builder /etc/nginx /etc/nginx
COPY --from=builder /var/log/nginx /var/log/nginx
RUN useradd nginx && mkdir -p /usr/local/nginx/client_body_temp && \
    chown -R nginx:nginx /usr/local/nginx/ && \
    apt update && \
    apt install -yqq libpcre3 libssl3 geoip-bin && \
    rm -rf /var/lib/apt/lists/* && \
    apt clean all

CMD [ "/usr/sbin/nginx" ]
