#!/usr/bin/env bats

source ../bin/securebox-backup-library.sh

# echo "SECUREBOX_BACKUP_LIBRARY_VERSION $SECUREBOX_BACKUP_LIBRARY_VERSION"

@test "webapp-driver-joomla-mysql" {

  run securebox_common_options_project_joomla ./apps/joomla-mysql/configuration.php

  echo "# SOURCE_MARIADB_HOST: $SOURCE_MARIADB_HOST" >&3
  if [ $SOURCE_MARIADB_HOST != "TEST_SOURCE_MARIADB_HOST_TEST" ]; then
    exit 1
  fi
  echo "# SOURCE_MARIADB_DBNAME: $SOURCE_MARIADB_DBNAME" >&3
  if [ $SOURCE_MARIADB_DBNAME != "TEST_SOURCE_MARIADB_DBNAME_TEST" ]; then
    exit 1
  fi
  echo "# SOURCE_MARIADB_USER: $SOURCE_MARIADB_USER" >&3
  if [ $SOURCE_MARIADB_USER != "TEST_SOURCE_MARIADB_USER_TEST" ]; then
    exit 1
  fi
  echo "# SOURCE_MARIADB_PASS: $SOURCE_MARIADB_PASS" >&3
  if [ $SOURCE_MARIADB_PASS != "TEST_SOURCE_MARIADB_PASS_TEST" ]; then
    exit 1
  fi
}

# @test "webapp-driver-laravel-mysql" {

#   run securebox_common_options_project_laravel ./apps/laravel-mysql/.env

#   assert_success

#   assert_equal  1 1
#   exit 0

#   echo "# SOURCE_MARIADB_HOST: $SOURCE_MARIADB_HOST" >&3

#   run : ${SOURCE_MARIADB_HOST?"mysql"} 
#   assert_success 

#   [[ "$SOURCE_MARIADB_HOST" == "mysql" ]]
#   # [ $SOURCE_MARIADB_HOST == "mysql" ]

#   if [ $SOURCE_MARIADB_HOST != "TEST_SOURCE_MARIADB_HOST_TEST2" ]; then
#     return 1
#   fi
#   echo "# SOURCE_MARIADB_DBNAME: $SOURCE_MARIADB_DBNAME" >&3
#   if [ $SOURCE_MARIADB_DBNAME != "TEST_SOURCE_MARIADB_DBNAME_TEST" ]; then
#     return 1
#   fi
#   echo "# SOURCE_MARIADB_USER: $SOURCE_MARIADB_USER" >&3
#   if [ $SOURCE_MARIADB_USER != "TEST_SOURCE_MARIADB_USER_TEST" ]; then
#     return 1
#   fi
#   echo "# SOURCE_MARIADB_PASS: $SOURCE_MARIADB_PASS" >&3
#   if [ $SOURCE_MARIADB_PASS != "TEST_SOURCE_MARIADB_PASS_TEST" ]; then
#     return 2
#   fi
# }

# @test "addition using bc" {
#   result="$(echo 2+2 | bc)"
#   [ "$result" -eq 4 ]
# }

# @test "addition using dc" {
#   result="$(echo 2 2+p | dc)"
#   [ "$result" -eq 4 ]
# }