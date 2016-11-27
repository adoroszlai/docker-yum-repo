FROM centos:centos6

VOLUME /var/repo
WORKDIR /var/repo

RUN yum install -y \
    createrepo \
    perl \
    yum-utils \
  && yum clean all

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
