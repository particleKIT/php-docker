FROM php:5.6-apache

RUN apt-get update && apt-get upgrade && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng12-dev \
    && docker-php-ext-install -j$(nproc) iconv mcrypt \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd 

RUN a2enmod rewrite ssl && service apache2 restart 

EXPOSE 80
EXPOSE 443

RUN /usr/bin/install -d -o 33 -g 33 /var/log/apache2 

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

