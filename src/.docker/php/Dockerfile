FROM php:8.3-fpm

# avoid debconf and initrd
ENV DEBIAN_FRONTEND noninteractive
ENV INITRD No 

ENV DOCKER_IMAGE php-fpm
ENV DOCKER_NAME php-fpm
ENV PROJECT_PATH /var/www/lingoda
ENV TZ Europe/Vienna

# add user
ENV BUILD_USER=1000
ENV BUILD_USER_GROUP=1000
RUN useradd -d /home/lingoda -m -u $BUILD_USER -g www-data lingoda && \
    echo ". /etc/bash.bashrc" >> /home/lingoda/.bashrc

RUN groupadd -g $BUILD_USER_GROUP lingoda && \
    usermod -a -G lingoda lingoda

ENV PHP_AUTOCONF="/usr/bin/autoconf"

RUN set -eux && \
    rm -rf /usr/local/etc/php-fpm.d &&\
    apt-get update && \
    apt-get install -y --no-install-recommends\
        default-mysql-client \
        git \
        patch \
        pv \
        vim-tiny \
        unzip \
        autoconf && \
    docker-php-ext-install \ 
        pdo pdo_mysql mysqli && \
    # bashrc
    echo "\
    export PS1=\"\${usercolor}\\\u\\\[\\\033[0;33m\\\]@\${hostcolor}\${DOCKER_NAME} \\\[\\\033[0;36m\\\]\\\w \$ \\\[\\\033[00m\\\] \"\n\
    alias ll='ls -lh --color' \n\
    alias vim='vim.tiny' \n\
    if [[ -v PROJECT_PATH && -d \"\$PROJECT_PATH\" ]]; then cd \"\$PROJECT_PATH\"; fi \n\
    " >> /etc/bash.bashrc && \
    # cleanup
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
    rm -rf /var/lib/apt/lists/*

RUN curl -sS https://get.symfony.com/cli/installer | bash \
   && mv /root/.symfony5/bin/symfony /usr/local/bin/symfony

COPY --from=composer /usr/bin/composer /usr/bin/composer


ENV COMPOSER_CACHE_DIR=/var/www/.composer

COPY ./conf /usr/local/etc/

RUN chown -R lingoda:lingoda /usr/local/etc

## php.ini
ENV PHP_DATE_TIMEZONE "Europe/Vienna"
ENV PHP_DISPLAY_ERRORS "Off"
ENV PHP_DISPLAY_STARTUP_ERRORS "Off"
ENV PHP_ERROR_LOG="/proc/self/fd/2"
## https://maximivanov.github.io/php-error-reporting-calculator/ use integer
ENV PHP_ERROR_REPORTING "24575"
ENV PHP_MEMORY_LIMIT "2G"
ENV PHP_MAX_EXECUTION_TIME "30"
ENV PHP_POST_MAX_SIZE "1G"
ENV PHP_REALPATH_CACHE_SIZE=4096K
ENV PHP_REALPATH_CACHE_TTL=600
ENV PHP_UPLOAD_MAX_FILESIZE "1G"

## opcache settings
ENV OPCACHE_CONSISTENCY_CHECKS 0
ENV OPCACHE_ENABLE 1
ENV OPCACHE_ENABLE_CLI 1
ENV OPCACHE_JIT_BUFFER_SIZE 256M
ENV OPCACHE_PRELOAD_USER "www-data"
ENV OPCACHE_PRELOAD "/usr/local/etc/php/preload.php"
ENV OPCACHE_MEMORY_CONSUMPTION 512
ENV OPCACHE_MAX_ACCELERATED_FILES 100000
ENV OPCACHE_VALIDATE_TIMESTAMPS 1

RUN mkdir -p /var/log/php/;
RUN chmod -R o+w /var/log/php;

## php-fpm.ini
ENV PHP_FPM_ERROR_LOG="/proc/self/fd/2"
ENV PHP_FPM_ACCESS_LOG="/var/log/php/php-fpm-access.log"
ENV PHP_FPM_PORT 9000
ENV PHP_FPM_PM dynamic
ENV PHP_FPM_PM_MAX_CHILDREN 20
ENV PHP_FPM_PM_START_SERVERS 10
ENV PHP_FPM_PM_MAX_SPARE_SERVERS 10
ENV PHP_FPM_PM_MIN_SPARE_SERVERS 4
ENV PHP_FPM_PM_MAX_REQUESTS 10000
ENV PHP_FPM_CATCH_WORKERS_OUTPUT 1
ENV PHP_FPM_LOG_ERRORS 1

RUN mkdir -p /var/www/lingoda

WORKDIR /var/www/lingoda
RUN chown -R lingoda:www-data /var/www

USER lingoda

RUN composer create-project symfony/symfony-demo /var/www/lingoda
RUN composer require webapp
RUN composer install

RUN mkdir -p /var/www/lingoda/volumes/
RUN mkdir -p /var/www/lingoda/volumes/public/
RUN mkdir -p /var/www/lingoda/volumes/var/

RUN cp -r /var/www/lingoda/public/ /var/www/lingoda/volumes/
RUN cp -r /var/www/lingoda/var/ /var/www/lingoda/volumes/

USER root

COPY ./build/init.sh /var/www/lingoda/bin/
RUN chown -R lingoda:www-data /var/www/lingoda/bin/init.sh
COPY ./build/doctrine.yaml /var/www/lingoda/config/packages/doctrine.yaml
RUN chown -R lingoda:www-data /var/www/lingoda/config/packages/doctrine.yaml

USER lingoda