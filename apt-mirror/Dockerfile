FROM debian:stretch-slim

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -q -y update \
  && apt-get -y --no-install-recommends install \
    apt-mirror \
    curl \
  && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
