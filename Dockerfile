FROM php:5.6-apache

RUN usermod -u 1000 www-data && groupmod -g 1000 www-data

RUN apt-get update && apt-get upgrade -y && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng12-dev \
        libldap2-dev \
        ssmtp \
    && docker-php-ext-install -j$(nproc) iconv mcrypt \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \ 
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-install ldap

COPY php.ini /usr/local/etc/php/

RUN sed -i 's/TLS_CACERT.*$/TLS_CACERT \/etc\/apache2\/ssl\/ldap.pem/g' /etc/ldap/ldap.conf

RUN echo "Europe/Berlin" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata

RUN a2enmod rewrite ssl headers userdir && service apache2 restart 

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

