FROM centos:centos6

VOLUME /var/repo
WORKDIR /var/repo

RUN yum -q -y install \
    createrepo \
    perl \
    yum-utils \
  && yum clean all

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
