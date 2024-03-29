FROM ubuntu:22.04

RUN usermod -u 1000 www-data && groupmod -g 1000 www-data

RUN apt-get update && apt-get upgrade -y && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    apache2 mcrypt php-gd php-ldap php-xml php-mbstring \
    libapache2-mod-php ca-certificates sendmail

RUN sed -i 's/TLS_CACERT.*$/TLS_CACERT \/etc\/apache2\/ssl\/ldap.pem/g' /etc/ldap/ldap.conf &&\
    ln -fs /usr/share/zoneinfo/Europe/Berlin /etc/localtime && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure -f noninteractive tzdata &&\
    a2enmod rewrite ssl headers userdir authz_groupfile && \
    /usr/bin/install -d -o www-data -g www-data /var/log/apache2 &&\
    sed -i 's/^upload_max_filesize.*$/upload_max_filesize=100M/' /etc/php/8.*/apache2/php.ini &&\
    sed -i 's/^upload_max_filesize.*$/upload_max_filesize=100M/' /etc/php/8.*/apache2/php.ini &&\
    sed -i 's/^memory_limit.*$/memory_limit = 500M/' /etc/php/8.*/apache2/php.ini &&\
    sed -i 's/^;date.timezone.*$/date.timezone="Europe\/Berlin"/' /etc/php/8.*/apache2/php.ini

EXPOSE 80 443

VOLUME ["/var/www/html", "/etc/apache2/sites-enabled", "/etc/apache2/conf-enabled", "/etc/apache2/ssl"]

ENV APACHE_RUN_USER=www-data \
    APACHE_RUN_GROUP=www-data \
    APACHE_PID_FILE=/var/run/apache2/apache2.pid \
    APACHE_RUN_DIR=/var/run/apache2 \
    APACHE_LOCK_DIR=/var/lock/apache2 \
    APACHE_LOG_DIR=/var/log/apache2 \
    LANG=C

CMD ["/usr/sbin/apache2", "-DFOREGROUND"]
