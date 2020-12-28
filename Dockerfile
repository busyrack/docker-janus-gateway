FROM debian:stable

LABEL maintainer="Linagora Folks <lgs-openpaas-dev@linagora.com>, BusyRack <dev@busyrack.com>"
LABEL description="Provides an image with Janus Gateway"

RUN apt-get update -y \
    && apt-get upgrade -y

RUN apt-get install -y \
    build-essential \
    libmicrohttpd-dev \
    libjansson-dev \
    libnice-dev \
    libssl-dev \
    libconfig-dev \
    libsofia-sip-ua-dev \
    libglib2.0-dev \
    libopus-dev \
    libogg-dev \
    libini-config-dev \
    libcollection-dev \
    pkg-config \
    gengetopt \
    libtool \
    autotools-dev \
    automake

RUN apt-get install -y \
    sudo \
    make \
    git \
    cmake

RUN cd ~ \
    && git clone https://github.com/cisco/libsrtp.git \
    && cd libsrtp \
    && git checkout v2.3.0 \
    && ./configure --prefix=/usr --enable-openssl \
    && make shared_library \
    && sudo make install

RUN cd ~ \
    && git clone https://github.com/sctplab/usrsctp \
    && cd usrsctp \
    && ./bootstrap \
    && ./configure --prefix=/usr \
    && make \
    && sudo make install

RUN cd ~ \
    && git clone https://github.com/warmcat/libwebsockets.git \
    && cd libwebsockets \
    && git checkout v4.1.4 \
    && mkdir build \
    && cd build \
    && cmake -DLWS_MAX_SMP=1 -DCMAKE_INSTALL_PREFIX:PATH=/usr -DCMAKE_C_FLAGS="-fpic" .. \
    && make \
    && sudo make install

RUN cd ~ \
    && git clone https://github.com/meetecho/janus-gateway.git \
    && cd janus-gateway \
    && sh autogen.sh \
    && ./configure --prefix=/opt/janus --disable-rabbitmq --disable-mqtt \
    && make CFLAGS='-std=c99' \
    && make install \
    && make configs

#RUN cp -rp ~/janus-gateway/certs /opt/janus/share/janus
#RUN openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -keyout /opt/janus/share/janus/mycert.key -out  /opt/janus/share/janus/mycert.pem

COPY conf/*.cfg /opt/janus/etc/janus/

RUN apt-get install nginx -y
COPY nginx/nginx.conf /etc/nginx/nginx.conf

RUN openssl dhparam -out /etc/nginx/ssl-dhparams.pem 1024

EXPOSE 80 7088 8088 8188 8089
EXPOSE 10000-10200/udp

CMD service nginx restart && /opt/janus/bin/janus --nat-1-1=${DOCKER_IP}
