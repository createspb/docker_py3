FROM createdigitalspb/docker_logstash_baseimage:1.0
MAINTAINER Create Digital <hello@createdigital.me>

ENV HOME /root
CMD ["/sbin/my_init"]

RUN apt-get update -qy &&\
    apt-get install -qy binutils libproj-dev gdal-bin libgeoip1 build-essential &&\
    apt-get purge -y python.*

#
# The instructions below are copied from the official python 3.5 image, with slight modifications.
# Unfortunately, there are no good ppa with python3.5 and it's dev version at the moment. So we build python from souce.
# Hopefully, it will be changed in future.
#

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8

# gpg: key F73C700D: public key "Larry Hastings <larry@hastings.org>" imported
ENV GPG_KEY 97FC712E4C024BBEA48A61ED3A5CA953F73C700D

ENV PYTHON_VERSION 3.5.1

# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
# we need pip < 8.0 as the newer versions cause problems with buildout
ENV PYTHON_PIP_VERSION 7.1.2

RUN set -ex \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEY" \
	&& curl -fSL "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" -o python.tar.xz \
	&& curl -fSL "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz.asc" -o python.tar.xz.asc \
	&& gpg --verify python.tar.xz.asc \
	&& mkdir -p /usr/src/python \
	&& tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
	&& rm python.tar.xz* \
	&& rm -r ~/.gnupg \
	\
	&& cd /usr/src/python \
	&& ./configure --prefix=/usr --enable-shared --enable-unicode=ucs4 \
	&& make -j$(nproc) \
	&& make install \
	&& ldconfig \
  && pip3 install --no-cache-dir --upgrade --ignore-installed pip==$PYTHON_PIP_VERSION \
	&& find /usr/local \
		\( -type d -a -name test -o -name tests \) \
		-o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
		-exec rm -rf '{}' + \
	&& rm -rf /usr/src/python

ADD requirements.txt /tmp/requirements.txt
RUN cd /tmp && pip3 install -r /tmp/requirements.txt

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV PYTHONENCODING utf8
