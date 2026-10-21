FROM debian:13

# --- cache-busting -----------------------------------------------------------
# The image is rebuilt weekly by the 'automatedbuilds' ansible role on
# vserverhost2. Without this ARG, docker reuses the cached 'apt-get install'
# layer, so a Debian security update (e.g. the PHP2Shell fixes
# CVE-2026-109618 / CVE-2026-109619 in php8.4 8.4.27) would NOT be picked up
# and the weekly build would silently re-publish the old, vulnerable image.
# The role also passes build.nocache=true; this ARG makes the build correct
# even when it does not, and it is visible in the image history.
ARG CACHEBUST=1
RUN echo "cachebust=${CACHEBUST} build=$(date -u +%FT%TZ)" > /etc/php-cachebust

RUN usermod -u 1000 www-data && groupmod -g 1000 www-data

RUN apt-get update && apt-get upgrade -y && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    apache2 mcrypt php-gd php-ldap php-xml php-mbstring \
    libapache2-mod-php ca-certificates sendmail libapache2-mod-security2

RUN sed -i 's/TLS_CACERT.*$/TLS_CACERT \/etc\/apache2\/ssl\/ldap.pem/g' /etc/ldap/ldap.conf &&\
    ln -fs /usr/share/zoneinfo/Europe/Berlin /etc/localtime && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure -f noninteractive tzdata &&\
    a2enmod rewrite ssl headers userdir authz_groupfile security2 && \
    /usr/bin/install -d -o www-data -g www-data /var/log/apache2 &&\
    sed -i 's/^upload_max_filesize.*$/upload_max_filesize=8M/' /etc/php/8.*/apache2/php.ini &&\
    sed -i 's/^memory_limit.*$/memory_limit = -1/' /etc/php/8.*/apache2/php.ini &&\
    sed -i 's/^;date.timezone.*$/date.timezone="Europe\/Berlin"/' /etc/php/8.*/apache2/php.ini

RUN mkdir -p /etc/modsecurity/ && \
  printf '%s\n' \
    'SecRuleEngine On' \
    'SecRequestBodyAccess On' \
    'SecResponseBodyAccess Off' \
    'SecDefaultAction "phase:1,log,auditlog,pass"' \
    'SecAuditEngine RelevantOnly' \
    'SecAuditLog /var/log/apache2/modsec_audit.log' \
    'SecDebugLog /var/log/apache2/modsec_debug.log' \
    'SecDebugLogLevel 1' \
    'SecRequestBodyLimit 13107200' \
    'SecRequestBodyNoFilesLimit 131072' \
    'SecRequestBodyInMemoryLimit 131072' \
    'SecPcreMatchLimit 1000000' \
    'SecPcreMatchLimitRecursion 1000000' \
    'Include /etc/modsecurity.d/rules/*.conf' \
    > /etc/modsecurity/modsecurity.conf

RUN mkdir -p /etc/modsecurity.d/rules && \
    echo '# dummy placeholder rule' > /etc/modsecurity.d/rules/dummy.conf

# PHP2Shell hardening (CVE-2026-109618, CVE-2026-109619, 2026-10-21)
#
# 109618 "RCE via OOM corruption": a *finite* memory_limit is the controllable
#   trigger - upstream advises memory_limit=-1 plus a low post_max_size.
#   (the pre-fix image shipped memory_limit=500M, i.e. the exploitable state)
# 109619 "RCE via stale global state": session.upload_progress must be off.
#
# Applied to the Apache SAPI *and* the CLI SAPI via conf.d, so it cannot be
# overridden by a later sed on the main php.ini. The upstream advisory
# explicitly warns against relying on ini_set() or .user.ini here.
RUN printf '%s\n' \
    'memory_limit = -1' \
    'post_max_size = 8M' \
    'upload_max_filesize = 8M' \
    'session.upload_progress.enabled = 0' \
    'session.upload_progress.cleanup = On' \
    'max_input_vars = 1000' \
    'max_file_uploads = 10' \
    > /etc/php/8.4/apache2/conf.d/99-php2shell-hardening.ini && \
    printf '%s\n' \
    'memory_limit = -1' \
    'post_max_size = 8M' \
    'upload_max_filesize = 8M' \
    'session.upload_progress.enabled = 0' \
    'session.upload_progress.cleanup = On' \
    > /etc/php/8.4/cli/conf.d/99-php2shell-hardening.ini

EXPOSE 80 443

VOLUME ["/var/www/html", "/etc/apache2/sites-enabled", "/etc/apache2/conf-enabled", "/etc/apache2/ssl", "/etc/modsecurity.d/rules"]

ENV APACHE_RUN_USER=www-data \
    APACHE_RUN_GROUP=www-data \
    APACHE_PID_FILE=/var/run/apache2/apache2.pid \
    APACHE_RUN_DIR=/var/run/apache2 \
    APACHE_LOCK_DIR=/var/lock/apache2 \
    APACHE_LOG_DIR=/var/log/apache2 \
    LANG=C

CMD ["/usr/sbin/apache2", "-DFOREGROUND"]
