#!/bin/bash

echo "Running sanity checks..."

test -f server_health_audit.sh || exit 1
test -x server_health_audit.sh || exit 1

./server_health_audit.sh --help >/dev/null 2>&1 || true

echo "Sanity checks passed"
