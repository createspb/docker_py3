FROM createdigitalspb/docker_logstash_baseimage:1.0
MAINTAINER Create Digital <hello@createdigital.me>

ENV HOME /root
CMD ["/sbin/my_init"]

RUN apt-get update -qy && apt-get install -qy python3-pip python3-dev

ADD requirements.txt /tmp/requirements.txt
RUN cd /tmp && pip3 install -r /tmp/requirements.txt

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV PYTHONENCODING utf8
