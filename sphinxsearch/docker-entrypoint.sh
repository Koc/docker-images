#!/bin/sh
set -e

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- run-sphinxsearch.sh "$@"
fi

exec "$@"
