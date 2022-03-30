#!/bin/sh
set -e

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
  set -- php-fpm "$@"
fi

/usr/local/bin/wait_db
/usr/local/bin/install

if [ "$1" = 'php-fpm' ] || [ "$1" = 'bin/console' ]; then
  mkdir -p var/cache var/log public/var
  chown www-data: var/cache var/log public/var
  bin/console pimcore:deployment:classes-rebuild --no-interaction || true
fi

chown -R www-data: .

exec docker-php-entrypoint "$@"
