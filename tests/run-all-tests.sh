#!/bin/sh


# TODO: remove these vanilla tests (fititnt, 17:42 UTC)
echo "vanilla, inicio"

. ../bin/securebox-backup-library.sh
securebox_common_options_project_joomla ./apps/joomla-mysql/configuration.php
echo "SOURCE_MARIADB_DBNAME $SOURCE_MARIADB_DBNAME"
echo "SOURCE_MARIADB_HOST $SOURCE_MARIADB_HOST"
echo "SOURCE_MARIADB_USER $SOURCE_MARIADB_USER"
echo "SOURCE_MARIADB_PASS $SOURCE_MARIADB_PASS"

echo "vanilla, fim"

echo "webapp-drivers.bats"
bats webapp-drivers.bats


