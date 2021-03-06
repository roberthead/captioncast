############################################################
# OSF First DockerFile
# A Docker Container Installation of CaptionCast
############################################################

#Declar CentOS the latest
FROM centos

Maintainer Andrew J Krug

RUN yum update -y

RUN yum install epel-release -y

RUN yum install -y nginx curl nodejs
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

RUN yum install gcc make rubygem-nokogiri libxslt libxslt-devel libxml2 libxml2-devel sqlite-devel openssl-devel ruby-devel rubygem-devel rubygem-bundler -y

RUN gem install nokogiri -- --use-system-libraries

ADD config/container/nginx-sites.conf /etc/nginx/conf.d/default.conf
ADD config/container/start-server.sh /usr/bin/start-server
RUN chmod +x /usr/bin/start-server

# Add rails project to project directory
ADD ./ /rails

# set WORKDIR
WORKDIR /rails

# bundle install
RUN /bin/bash -l -c "bundle install"

# Publish port 80
EXPOSE 80

# Startup commands
ENTRYPOINT /usr/bin/start-server
