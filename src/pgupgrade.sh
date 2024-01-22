#!/usr/bin/env bash

set -e
set -x

PG_VERSION="$(cat /var/lib/postgres/data/PG_VERSION)"

if [ -z "${PG_VERSION}" ]; then
  echo "No PG_VERSION found in /var/lib/postgres/data/PG_VERSION"
  exit 1
fi

mv /var/lib/postgres/data /var/lib/postgres/data-${PG_VERSION}
mkdir -p /var/lib/postgres/data
chown postgres:postgres /var/lib/postgres/data
chmod 700 /var/lib/postgres/data

su - postgres -c "initdb -D /var/lib/postgres/data --locale=en_US.UTF-8  --data-checksums"

su - postgres -c "/opt/pgsql-${PG_VERSION}/bin/pg_upgrade \
  -b /opt/pgsql-${PG_VERSION}/bin/ \
  -B /usr/bin/ \
  -d /var/lib/postgres/data-${PG_VERSION} \
  -D /var/lib/postgres/data"

