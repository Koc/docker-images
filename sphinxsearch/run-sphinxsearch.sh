#!/bin/bash
set -e

exec $(which searchd) --config /etc/sphinxsearch/sphinx.conf --nodetach "$@"
