FROM alpine:3.14

# Do a system update
RUN apk update && apk upgrade
# Install packages and remove default server definition
RUN apk --no-cache add \
  curl \
  nginx \
  php \
  php7-pear\
  php7-dev\
  gcc\
  musl-dev\
  make\
  php-ctype \
  php-curl \
  php-dom \
  php-fpm \
  php-gd \
  php-intl \
  php-json \
  php-mbstring \
  php-mysqli \
  php-opcache \
  php-openssl \
  php-phar \
  php-session \
  php-xml \
  php-xmlreader \
  php-zlib \
  supervisor \
  gettext

# Install Redis

RUN pecl install redis

# Create symlink so programs depending on `php` still function
#RUN ln -s /usr/bin/php7 /usr/bin/php

# Configure nginx
COPY config/nginx/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY config/php/fpm-pool.conf /etc/php7/php-fpm.d/www.conf
COPY config/php/php.ini /etc/php7/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Setup document root
RUN mkdir -p /var/www/html

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /var/www/html && \
  chown -R nobody.nobody /run && \
  chown -R nobody.nobody /var/lib/nginx && \
  chown -R nobody.nobody /var/log/nginx

# Switch to use a non-root user from here on
USER nobody

# Add application
WORKDIR /var/www/html
#COPY  src/ /var/www/html/

# Expose the port nginx is reachable on
EXPOSE 80

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
# HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:80/fpm-ping