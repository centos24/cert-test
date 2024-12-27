FROM oraclelinux:7-slim

RUN \
  yum update -y && \
  yum install java-1.8.0-openjdk -y && \
  yum install sudo -y && \
  yum clean all && \
  mkdir -p /opt/csvn && \
  mkdir -p /svndata/repo && \
  groupadd -g 1000 csvn && \
  useradd -m -g csvn -u 1000 csvn && \
  chown -R csvn:csvn /opt/csvn && \
  chown -R csvn:csvn /svndata/repo

EXPOSE 3343 4434 443

docker run -dit --name test --restart unless-stopped -e TZ=Etc/Warsaw -v /svndata/repo:/svndata/repo ol7-svn:7-slim
