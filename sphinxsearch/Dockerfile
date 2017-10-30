FROM phusion/baseimage

ENV SPHINX_VERSION 2.2.11

ARG DEBIAN_FRONTEND=noninteractive

# prepare required software
RUN apt-get update \
 && apt-get install -y \
    mc vim wget curl make \
    htop \
    tar bzip2 gzip \
    python-software-properties \
    autoconf g++ \
    dpkg-dev \
    php7.0-cli \
 && rm -rf /var/lib/apt/lists/* && rm -rf /var/cache/apk/* && rm -rf /tmp/*

# build sphinx from sources and patch it
RUN mkdir /tmp/sphinx-build && cd /tmp/sphinx-build \
 && add-apt-repository -s ppa:builds/sphinxsearch-rel22 \
 && apt-get update \
 && apt-get source sphinxsearch=$SPHINX_VERSION \
 && apt-get build-dep -y sphinxsearch=$SPHINX_VERSION \
 && wget https://bitbucket.org/Koc/sphinx-udf/raw/default/patchattrsorting.patch \
 && patch -p0 < patchattrsorting.patch \
 && cd sphinxsearch-$SPHINX_VERSION-release \
 && dpkg-buildpackage -rfakeroot -uc -b \
 && dpkg -i ../sphinxsearch_$SPHINX_VERSION-release-0ubuntu13~xenial_amd64.deb \
 && rm -rf /var/lib/apt/lists/* && rm -rf /var/cache/apk/* && rm -rf /tmp/*

# build udf
RUN mkdir /tmp/sphinx-build && cd /tmp/sphinx-build \
 && wget http://sphinxsearch.com/files/sphinx-$SPHINX_VERSION-release.tar.gz \
 && tar -xzvf sphinx-$SPHINX_VERSION-release.tar.gz \
 && cd sphinx-$SPHINX_VERSION-release/src \
 && mkdir /usr/lib/sphinxsearch \
 && wget https://bitbucket.org/Koc/sphinx-udf/raw/default/uniqueserial.cpp \
 && gcc -fPIC -shared -o uniqueserial.so uniqueserial.cpp \
 && mv uniqueserial.so /usr/lib/sphinxsearch \
 && wget https://bitbucket.org/Koc/sphinx-udf/raw/default/disorderly.cpp \
 && gcc -fPIC -shared -o disorderly.so disorderly.cpp \
 && mv disorderly.so /usr/lib/sphinxsearch \
 && wget https://bitbucket.org/Koc/sphinx-udf/raw/default/increasepriority.cpp \
 && gcc -fPIC -shared -o increasepriority.so increasepriority.cpp \
 && mv increasepriority.so /usr/lib/sphinxsearch \
 && rm -rf /tmp/*

VOLUME ["/etc/sphinxsearch", "/var/lib/sphinxsearch", "/var/log/sphinxsearch"]
WORKDIR /etc/sphinxsearch

COPY docker-entrypoint.sh /usr/local/bin/
COPY run-sphinxsearch.sh /usr/local/bin/

EXPOSE 9306

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["run-sphinxsearch.sh"]
