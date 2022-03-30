ARG PHP_VERSION=8.0
ARG NGINX_VERSION=1.21

FROM pimcore/pimcore:PHP${PHP_VERSION}-fpm AS cors_php
WORKDIR /var/www/html

ENV APP_ENV=prod
ARG COMPOSER_AUTH

COPY composer.* ./
COPY bin bin/
COPY public/index.php public/index.php
COPY public/static public/static
#Since it's a DEMO we also copy the public/var dir, in a production env you would not do that
COPY public/var public/var
#Since it's a DEMO we also copy the dump
COPY dump dump
COPY config config/
COPY src src/
COPY templates templates/
COPY translations translations/
COPY var var/
COPY .env .env
COPY .docker/php/docker-entrypoint.sh /usr/local/bin/entrypoint
COPY .docker/php/docker-install.sh /usr/local/bin/install
COPY .docker/php/docker-wait-db.sh /usr/local/bin/wait_db

RUN set -eux; \
    chmod +x /usr/local/bin/entrypoint; \
    chmod +x /usr/local/bin/install; \
    chmod +x /usr/local/bin/wait_db; \
    composer install --prefer-dist --no-scripts --no-progress; \
    bin/console cache:clear; \
    mkdir -p var/cache var/log; \
    composer dump-autoload; \
    chmod +x bin/console; \
    sleep 1; \
    bin/console assets:install; \
    sync;

RUN chown -R www-data: /var/www/html

ENTRYPOINT ["entrypoint"]
CMD ["php-fpm"]

FROM nginx:${NGINX_VERSION}-alpine AS cors_nginx

WORKDIR /var/www/html
COPY .docker/nginx/nginx-default.conf /etc/nginx/conf.d/default.conf
COPY --from=cors_php /var/www/html/public public/
