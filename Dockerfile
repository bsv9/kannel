FROM ubuntu:20.04 AS builder

ARG DEBIAN_FRONTEND=noninteractive

ENV DOWNLOAD_SHA256 aff43c9c6bb371f73280ed07385323b9b42363501cfe13c5ecef925dd926c60c

RUN apt-get update && apt-get install -y \
    bison \
    wget \
    build-essential \
    automake \
    libtool \
    autoconf \
    libxml2-dev \
    libssl-dev
RUN  wget --no-check-certificate https://redmine.kannel.org/attachments/download/321/gateway-1.4.5.tar.bz2 && echo "$DOWNLOAD_SHA256 gateway-1.4.5.tar.bz2" | sha256sum -c - 
RUN tar jxvf gateway-1.4.5.tar.bz2
WORKDIR gateway-1.4.5
ADD gateway-1.4.5.patch.gz .
RUN gunzip -c gateway-1.4.5.patch.gz | patch -p1
RUN ./configure --prefix=/usr --sysconfdir=/etc/kannel && touch .depend && make && make install

ADD bootstrap.patch addons/opensmppbox/
RUN (cd addons/opensmppbox && patch -p0 < bootstrap.patch && ./bootstrap && ./configure --prefix=/usr --sysconfdir=/etc/kannel && make && make install)
# RUN (cd addons/opensmppbox && patch -p0 < bootstrap.patch && ./bootstrap && ./configure && make && make install)

# WORKDIR /
# RUN rm gateway-1.4.5.tar.bz2 && rm -Rf gateway-1.4.5 && mkdir -p /var/log/kannel && mkdir -p /var/spool/kannel

FROM ubuntu:20.04
RUN apt-get update && apt-get install -y libxml2 openssl supervisor && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/sbin/bearerbox /usr/sbin/smsbox /usr/sbin/wapbox /usr/sbin/opensmppbox /usr/sbin/
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

WORKDIR /usr/sbin
EXPOSE 13000 13001 10000
VOLUME ["/var/spool/kannel", "/etc/kannel", "/var/log/kannel"]
CMD ["/usr/bin/supervisord"]
