FROM debian:jessie

RUN usermod -u 1000 www-data && groupmod -g 1000 www-data

RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    apache2 mcrypt php-pear php5-mcrypt php5-gd php5-ldap libfreetype6-dev \
    libjpeg62-turbo-dev libmcrypt-dev libpng12-dev libldap2-dev \
    libapache2-mod-php5 ca-certificates 

COPY php.ini /etc/php5/apache2/php.ini

RUN sed -i 's/TLS_CACERT.*$/TLS_CACERT \/etc\/apache2\/ssl\/ldap.pem/g' /etc/ldap/ldap.conf

RUN echo "Europe/Berlin" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata

RUN a2enmod rewrite ssl headers userdir authz_groupfile && service apache2 restart 

EXPOSE 80
EXPOSE 443

RUN /usr/bin/install -d -o www-data -g www-data /var/log/apache2 

VOLUME /var/www/html
VOLUME /etc/apache2/sites-enabled
VOLUME /etc/apache2/conf-enabled
VOLUME /etc/ssl

ENV APACHE_RUN_USER=www-data
ENV APACHE_RUN_GROUP=www-data
ENV APACHE_PID_FILE=/var/run/apache2/apache2.pid
ENV APACHE_RUN_DIR=/var/run/apache2
ENV APACHE_LOCK_DIR=/var/lock/apache2
ENV APACHE_LOG_DIR=/var/log/apache2
ENV LANG=C

CMD ["/usr/sbin/apache2", "-DFOREGROUND"]
