FROM phusion/baseimage:0.11
MAINTAINER BirgerK <romansavrulin@gmail.com>

ENV DEBIAN_FRONTEND noninteractive
ENV LETSENCRYPT_HOME /etc/letsencrypt
ENV DOMAINS ""
ENV WEBMASTER_MAIL ""
ENV WEBSERVER_HOSTNAME "localhost"
ENV STAGING ""

# Base setup
RUN apt-get -y update && \
    apt-get install -q -y curl apache2 software-properties-common iproute2 gawk mime-support iputils-ping && \
    add-apt-repository ppa:certbot/certbot && \
    apt-get -y update && \
    apt-get install -q -y python-certbot-apache && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# configure apache
ADD config/mods-available/proxy_html.conf /etc/apache2/mods-available/
ADD config/conf-available/security.conf /etc/apache2/conf-available/
RUN echo "ServerName $WEBSERVER_HOSTNAME" >> /etc/apache2/conf-enabled/hostname.conf
#RUN a2dissite 000-default default-ssl
RUN a2enmod ssl headers proxy proxy_http proxy_html xml2enc rewrite usertrack remoteip && \
    mkdir -p /var/lock/apache2 && \
    mkdir -p /var/run/apache2

# configure runit
RUN mkdir -p /etc/service/apache
ADD config/scripts/run_apache.sh /etc/service/apache/run
ADD config/scripts/init_letsencrypt.sh /etc/my_init.d/
ADD config/scripts/run_letsencrypt.sh /run_letsencrypt.sh
RUN chmod +x /*.sh && chmod +x /etc/my_init.d/*.sh && chmod +x /etc/service/apache/*

# Manually set the apache environment variables in order to get apache to work immediately.
RUN echo $WEBMASTER_MAIL > /etc/container_environment/WEBMASTER_MAIL && \
    echo $DOMAINS > /etc/container_environment/DOMAINS && \
    echo $LETSENCRYPT_HOME > /etc/container_environment/LETSENCRYPT_HOME

CMD ["/sbin/my_init"]

# Stuff
EXPOSE 80
EXPOSE 443
VOLUME [ "/var/log/apache2", "$LETSENCRYPT_HOME", "/etc/apache2/", "/var/www/html" ]
