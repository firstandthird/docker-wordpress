FROM php:7.1-apache

RUN a2enmod rewrite expires

# install the PHP extensions we need
RUN apt-get update && \
  apt-get install -y git libpng-dev libjpeg-dev default-mysql-client default-libmysqlclient-dev && \
  rm -rf /var/lib/apt/lists/* && \
  docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr && \
  docker-php-ext-install gd mysqli opcache

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
    echo 'opcache.enable=0'; \
} > /usr/local/etc/php/conf.d/opcache-recommended.ini

#https://github.com/docker-library/wordpress/blob/master/fpm/Dockerfile
ENV WORDPRESS_VERSION 5.3.2
ENV WORDPRESS_SHA1 fded476f112dbab14e3b5acddd2bcfa550e7b01b

# upstream tarballs include ./wordpress/ so this gives us /usr/src/wordpress
RUN curl -o wordpress.tar.gz -SL https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz \
  && echo "$WORDPRESS_SHA1 *wordpress.tar.gz" | sha1sum -c - \
  && tar -xzf wordpress.tar.gz -C /usr/src/ \
  && rm wordpress.tar.gz \
  && rm -rf /var/www/html \
  && mv /usr/src/wordpress /var/www/html \
  && chown -R www-data:www-data /var/www/html

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
  chmod +x wp-cli.phar && \
  mv wp-cli.phar /usr/local/bin/wp

RUN echo "alias wp='wp --allow-root'" >> ~/.bashrc

COPY .htaccess /var/www/html/.htaccess
COPY setup /setup

ENTRYPOINT ["/setup"]
CMD ["apache2-foreground"]
