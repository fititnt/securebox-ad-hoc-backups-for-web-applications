#!/bin/sh
#===============================================================================
#
#          FILE:  securebox-backup-library.sh
#
#         USAGE:  . securebox-backup-library.sh
#
#   DESCRIPTION:  securebox-backup-library.sh is an POSIX shell (it means is
#                 very portable) that holds common functionalities for the
#                 securebox-backup-* executables.
#                 Released under Public Domain license
#
#       OPTIONS:  ---
#
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Emerson Rocha <rocha[at]ieee.org>
#       COMPANY:  Etica.AI
#       LICENSE:  Public Domain
#       VERSION:  v2.0
#       CREATED:  2020-11-14 23:52 UTC Created. Based on securebox-backup-download v2.0
#      REVISION:  ---
#===============================================================================

# TODO: Implement some helper to allow bit rot protection. See
#       https://pthree.org/2014/04/01/protect-against-bit-rot-with-parchive/
#       (fititnt, 2020-11-15 01:59 BRT)

################################  Defaults, START ##############################

#TIMESTAMP=$(date +'%FT%T')

# TODO: use these docstrings https://google.github.io/styleguide/shellguide.html#s4.2-function-comments (fititnt, 2020-11-14 00:22 BRT)
# TODO: change identation to 2 spaces (fititnt, 2020-11-14 04:39 BRT)

# DRYRUN=""   # (enable: DRYRUN=1 ; disable: DRYRUN="" )
# DEBUG=""    # (enable: DEBUG=1 )
# # VERBOSE=""  # (enable: VERBOSE=1 )

export DEFAULT__SOURCE_HOST="user@example.com"
export DEFAULT__SOURCE_PATH="/var/www"

export DEFAULT__ORGANIZATION="default"
export DEFAULT__PROJECT="default"
export DEFAULT__WEBAPP_TYPE="generic" # This is autodetected. Do not need to change
export DEFAULT__LOCALMIRROR_BASEPATH="/backups/mirror"
export DEFAULT__LOCALARCHIVES_BASEPATH="/backups/archives"
export DEFAULT__LOCALTMP="/backups/tmp"
export DEFAULT__SUBDIR_FILES="files" # /backups/mirror/default/default/files/...
export DEFAULT__SUBDIR_MYSQLDUMP="mysqldump" # /backups/mirror/default/default/mysqldump/dbname.sql
# DEFAULT__LOCALMIRROR_THISPROJECT="$DEFAULT__LOCALMIRROR_BASEPATH/$DEFAULT__ORGANIZATION/$DEFAULT__PROJECT"

export DEFAULT__DOWNLOAD_RSYNC_EXCLUDES="--exclude '.well-known'"
export DEFAULT__DOWNLOAD_RSYNC_EXTRAOPTIONS=""

# This path is both for temporary files AND to, if you run this script too fast
# will not allow run again.
export DEFAULT__MYSQLDUMP_TMPANDLOCKDIR="/tmp/databasedump.lock"
export DEFAULT__MYSQLDUMP_EXCLUSIVELOCK="1"

# This script will atempt to create some local paths if they already do not exist
# You can define DEFAULT__SKIP_CREATE_LOCAL_FOLDERS=1 to create yourself
export DEFAULT__SKIP_CREATE_LOCAL_FOLDERS=
export DEFAULT__CREATE_LOCAL_FOLDERS_PERMISSIONS="0711"

# Even if you don't define MariaDB/MySQL credentials, this script will try to
#  guess if you are using Joomla/Wordpress/Moodle and download the database
# for you
export DEFAULT__SKIP_MYSQLDUMP=
export DEFAULT__SKIP_WEBAPP_TYPE_AUTODETECTION=

# Disable securebox_common_dont_run_as_root_please() check
export DEFAULT__SKIP_CHECK_DONT_RUN_AS_ROOT_LOCALLY=

#################################  Defaults, END ###############################

###############################  Functions, START ##############################


#######################################
# Quick documentation about example of boostrap local filesystem
# Globals:
#   Several (read-only mode)
# Arguments:
#   None
# Returns:
#   None
#######################################
securebox_common_help_boostrap_local() {
  echo "
$PROGRAM_NAME (via securebox-backup-library.sh) --help-bootstrap
  The securebox-backup-* tools are made in a way that does not require root on
  average usage, but if you are not put each individual component on an
  dedicated place, the base folders can have an know structure that works

  The complete explanations are on securebox-backups-overview.sh v1.1+. This
  quick guide does not cover all cases (like put on an removable media, lock
  unlock encryted mounts, etc).

    # Base folder
    sudo mkdir /backups/
    sudo chmod root:root /backups/

    # Permissions on base folder ('unlocked', 0711)
    sudo chmod 0711 /backups/
    # sudo chmod 0700 /backups/

    # LOCALTMP [$LOCALTMP], preverable on same local driver were you will archive
    sudo mkdir /backups/tmp
    sudo chmod 777 /backups/tmp
    sudo chown root:root /backups/tmp

    # LOCALMIRROR_BASEPATH [$LOCALMIRROR_BASEPATH]
    sudo mkdir /backups/mirror
    sudo chmod 777 /backups/mirror
    sudo chown root:root /backups/mirror

    # LOCALARCHIVES_BASEPATH [$LOCALARCHIVES_BASEPATH]
    sudo mkdir /backups/archives
    sudo chmod 777 /backups/archives
    sudo chown root:root /backups/archives

  How securebox-backup-* will create subfolders (no need your intervention)?
    Will use the CREATE_LOCAL_FOLDERS_PERMISSIONS [$CREATE_LOCAL_FOLDERS_PERMISSIONS]
      mkdir --mode=$CREATE_LOCAL_FOLDERS_PERMISSIONS (...)/org/project/(...)
    The owner will be the (preferable) non-root user you use to run

  Note: you can use an different strategy.
    "
}


#######################################
# Show all internal options at the moment
# Globals:
#   Several (read-only mode)
# Arguments:
#   None
# Returns:
#   None
#######################################
securebox_common_debug()
{
  # printf "========== securebox_common_debug, start ==========\n"
  printf "\nGeneral\n"
  echo "  ORGANIZATION: $ORGANIZATION"
  echo "  PROJECT: $PROJECT"
  # echo "LOCALTMP: $LOCALTMP"
  # echo "LOCALMIRROR_BASEPATH: $LOCALMIRROR_BASEPATH"
  # echo "LOCALMIRROR_BASEPATH: $LOCALMIRROR_BASEPATH"
  echo "  LOCALMIRROR_THISPROJECT: $LOCALMIRROR_THISPROJECT"
  echo "  LOCALARCHIVES_THISPROJECT: $LOCALARCHIVES_THISPROJECT"
  # echo "SUBDIR_FILES: $SUBDIR_FILES"
  # echo "SUBDIR_MYSQLDUMP: $SUBDIR_MYSQLDUMP"

  printf "\nSource of the project \n"
  printf "\n  Files \n"

  echo "    SOURCE_HOST: $SOURCE_HOST"
  echo "    SOURCE_PATH: $SOURCE_PATH"

  printf "\n  MariaDB/MySQL \n"

  echo "    SKIP_MYSQLDUMP: $SKIP_MYSQLDUMP"
  echo "    SOURCE_MARIADB_DBNAME: $SOURCE_MARIADB_DBNAME"
  echo "    SOURCE_MARIADB_HOST: $SOURCE_MARIADB_HOST"
  echo "    SOURCE_MARIADB_USER: $SOURCE_MARIADB_USER"
  echo "    SOURCE_MARIADB_PASS: $SOURCE_MARIADB_PASS"
  echo "    SOURCE_MARIADB_SKIP: $SOURCE_MARIADB_SKIP"
  echo "    SOURCE_MARIADB_SSHHOST: $SOURCE_MARIADB_SSHHOST"
  # echo "  _LOCALMIRROR_MARIADB_PATH: $_LOCALMIRROR_MARIADB_PATH"

  printf "\nInferences \n"
  echo "  WEBAPP_TYPE: $WEBAPP_TYPE"
  echo "  SKIP_WEBAPP_TYPE_AUTODETECTION: $SKIP_WEBAPP_TYPE_AUTODETECTION"

  printf "\nOther options \n"
  echo "  DRYRUN: $DRYRUN"
  echo "  DEBUG: $DEBUG"
  echo "  SKIP_WEBAPP_TYPE_AUTODETECTION: $DOWNLOAD_RSYNC_EXCLUDES"
  echo "  DOWNLOAD_RSYNC_EXCLUDES: $DOWNLOAD_RSYNC_EXCLUDES"
  echo "  DOWNLOAD_RSYNC_EXTRAOPTIONS: $DOWNLOAD_RSYNC_EXTRAOPTIONS"
  echo "  LOCALMIRROR_BASEPATH: $LOCALMIRROR_BASEPATH"
  echo "  LOCALMIRROR_THISPROJECT: $LOCALMIRROR_THISPROJECT"
  # echo "MYSQLDUMP_TMPANDLOCKDIR: $MYSQLDUMP_TMPANDLOCKDIR"
  # printf "========== securebox_common_debug, end ==========\n"
}

#######################################
# securebox-backup is designed to 
#
# Globals:
#   None
# Arguments:
#   Path of file to source for enviroment variables. Optional.
# Returns:
#   None
#######################################
securebox_common_dont_run_as_root_please() {
  # echo "SKIP_CHECK_DONT_RUN_AS_ROOT_LOCALLY [$SKIP_CHECK_DONT_RUN_AS_ROOT_LOCALLY]"
  if [ -z "$SKIP_CHECK_DONT_RUN_AS_ROOT_LOCALLY" ] && [ "$(whoami)" = "root" ]; then
    echo "This script is designed to run without root. If you are really sure, set"
    echo "  SKIP_CHECK_DONT_RUN_AS_ROOT_LOCALLY=1"
    echo "aborting"
    exit 1
  fi
}

#######################################
# Load enviroment variables (if they exist) from an file named
# securebox-backup.conf on the place where the executable is called and from
# the first parameter of the script
#
# Globals:
#   None
# Arguments:
#   Path of file to source for enviroment variables. Optional.
# Returns:
#   None
#######################################
securebox_common_options_securebox_confs() {
  _localvar_cliopt1="${1}"
  _localvar_defaultconf="$(pwd)/securebox-backup.conf"

  if [ -f "$_localvar_defaultconf" ]; then
    echo "securebox_common_options_securebox_confs:"
    echo "  $_localvar_defaultconf exists. Sourcing now"

    if [ "$(tr -cd '\r' < "$_localvar_defaultconf" | wc -c)" -gt 0 ]; then
      echo "The file seems to have CRLF instead of LF as line endings"
      echo "This may break things very, very bad. Refusing to continue"
      echo "Please use dos2unix $_localvar_defaultconf"
      exit 2
    fi
    # shellcheck source=/dev/null
    . "$_localvar_defaultconf"
  fi

  if [ -f "$_localvar_cliopt1" ]; then
    echo "securebox_common_options_securebox_confs:"
    echo "  $_localvar_cliopt1 exists. Sourcing now"

    if [ "$(tr -cd '\r' < "$_localvar_cliopt1" | wc -c)" -gt 0 ]; then
      echo "The file seems to have CRLF instead of LF as line endings"
      echo "This may break things very, very bad. Refusing to continue"
      echo "Please fix with something like"
      echo "    dos2unix $_localvar_cliopt1"
      exit 2
    fi
    # shellcheck source=/dev/null
    . "$_localvar_cliopt1"
  elif [ "$_localvar_cliopt1" != " -h" ] &&
    [ "$_localvar_cliopt1" != "--help" ] &&
    [ "$_localvar_cliopt1" != "--help-bootstrap" ]; then
    echo "$_localvar_cliopt1 File does not exit. Aborting."
    exit 2
  fi
}

#######################################
# ...
# Globals:
#   Several (read-only mode)
#   DOWNLOAD_RSYNC_DRYRUN_STRING  (depends on DRYRUN)
# Arguments:
#   None
# Returns:
#   None
#######################################
securebox_common_options_project ()
{
  # echo "securebox_options_inferece_from_project"

  # POSIX does support local keywork.
  _local_root="$LOCALMIRROR_THISPROJECT/$SUBDIR_FILES"

  if [ -f "${_local_root}/configuration.php" ]; then
    echo "securebox_options_inferece_from_project: trying Joomla..."
    securebox_common_options_project_joomla "${_local_root}/configuration.php"
  elif [ -f "${_local_root}/wp-config.php" ]; then
    echo "securebox_options_inferece_from_project: trying Wordpress..."
    securebox_common_options_project_wordpress "${_local_root}/configuration.php"
  elif [ -f "${_local_root}/config.php" ]; then
    echo "securebox_options_inferece_from_project: trying Moodle [/config.php]..."
    securebox_common_options_project_moodle "${_local_root}/config.php"
  elif [ -f "${_local_root}/configuration.php" ]; then
    echo "securebox_options_inferece_from_project: trying Moodle [/moodle/config.php]..."
    securebox_common_options_project_moodle "${_local_root}/moodle/config.php"
  fi
}

#######################################
# Parse a typical Joomla! configuration file and export global variables to be
# reused. Based on work from
# https://unix.stackexchange.com/questions/230102/parse-credentials-from-php-configuration-file
# Globals:
#   SOURCE_MARIADB_DBNAME
#   SOURCE_MARIADB_HOST
#   SOURCE_MARIADB_USER
#   SOURCE_MARIADB_PASS
# Arguments:
#   /path/to/joomla/configuration.php
# Returns:
#   None
#######################################
securebox_common_options_project_joomla ()
{
  SOURCE_MARIADB_DBNAME=$(grep -oP "\\\$db\s.+?'\K[^']+" "$1")
  SOURCE_MARIADB_HOST=$(grep -oP "\\\$host.+?'\K[^']+" "$1")
  SOURCE_MARIADB_USER=$(grep -oP "\\\$user.+?'\K[^']+" "$1")
  SOURCE_MARIADB_PASS=$(grep -oP "\\\$password.+?'\K[^']+" "$1")

  export SOURCE_MARIADB_DBNAME
  export SOURCE_MARIADB_HOST
  export SOURCE_MARIADB_USER
  export SOURCE_MARIADB_PASS
}

#######################################
# [draft] Parse an typical Moodle configuration file and export variables to be
# reused
# Globals:
#   SOURCE_MARIADB_DBNAME
#   SOURCE_MARIADB_HOST
#   SOURCE_MARIADB_USER
#   SOURCE_MARIADB_PASS
# Arguments:
#   /path/to/joomla/configuration.php
# Returns:
#   None
#######################################
securebox_common_options_project_moodle ()
{
  echo "Not implemented yet. You can use securebox_options_inferece_from_joomla reference"
}

#######################################
# [draft] Parse an typical Moodle configuration file and export variables to be
# reused
# Globals:
#   SOURCE_MARIADB_DBNAME
#   SOURCE_MARIADB_HOST
#   SOURCE_MARIADB_USER
#   SOURCE_MARIADB_PASS
# Arguments:
#   /path/to/wordpress/wp-config.php
# Returns:
#   None
#######################################
securebox_common_options_project_wordpress ()
{
  echo "Not implemented yet. You can use securebox_options_inferece_from_joomla reference"
}

#######################################
# Based on DEFAUL__* vars and what is discovered by
# securebox_common_options_securebox_confs the
# securebox_common_options_setdefaults will use the equivalent DEFAUL__* if the
# user did not customized. This funcion still not know about options detected
# From projects on disk, as defined on securebox_common_options_project
# Globals:
#   Several
#   DOWNLOAD_RSYNC_DRYRUN_STRING  (depends on DRYRUN)
# Arguments:
#   None
# Returns:
#   None
#######################################
securebox_common_options_setdefaults()
{
  ## About this project
  export ORGANIZATION="${ORGANIZATION:-$DEFAULT__ORGANIZATION}"
  export PROJECT="${PROJECT:-$DEFAULT__PROJECT}"
  export WEBAPP_TYPE="${WEBAPP_TYPE:-$DEFAULT__WEBAPP_TYPE}"
  export LOCALTMP="${LOCALTMP:-$DEFAULT__LOCALTMP}"
  export LOCALMIRROR_BASEPATH="${LOCALMIRROR_BASEPATH:-$DEFAULT__LOCALMIRROR_BASEPATH}"
  #export  DEFAULT__LOCALMIRROR_THISPROJECT="$DEFAULT__LOCALMIRROR_BASEPATH/$DEFAULT__ORGANIZATION/$DEFAULT__PROJECT"
  export LOCALMIRROR_THISPROJECT="${LOCALMIRROR_THISPROJECT:-$LOCALMIRROR_BASEPATH/$ORGANIZATION/$PROJECT}"
  export LOCALARCHIVES_BASEPATH="${LOCALARCHIVES_BASEPATH:-$DEFAULT__LOCALARCHIVES_BASEPATH}"
  export LOCALARCHIVES_THISPROJECT="${LOCALARCHIVES_THISPROJECT:-$LOCALARCHIVES_BASEPATH/$ORGANIZATION/$PROJECT}"
  export SUBDIR_FILES="${SUBDIR_FILES:-$DEFAULT__SUBDIR_FILES}"
  export SUBDIR_MYSQLDUMP="${SUBDIR_MYSQLDUMP:-$DEFAULT__SUBDIR_MYSQLDUMP}"

  ## About source
  export SOURCE_HOST="${SOURCE_HOST:-$DEFAULT__SOURCE_HOST}"
  export SOURCE_PATH="${SOURCE_PATH:-$DEFAULT__SOURCE_PATH}"

  # Specific to download rsync files
  export DOWNLOAD_RSYNC_EXCLUDES="${DOWNLOAD_RSYNC_EXCLUDES:-$DEFAULT__DOWNLOAD_RSYNC_EXCLUDES}"
  export DOWNLOAD_RSYNC_EXTRAOPTIONS="${DOWNLOAD_RSYNC_EXTRAOPTIONS:-$DEFAULT__DOWNLOAD_RSYNC_EXTRAOPTIONS}"

  ## Specific to mysqldump
  # We don't have default values for most MariaDB/MySQL vars, but we can
  # default the SSH host to the same SOURCE_HOST
  export SOURCE_MARIADB_SSHHOST="${SOURCE_MARIADB_SSHHOST:-$SOURCE_HOST}"
  export MYSQLDUMP_TMPANDLOCKDIR="${MYSQLDUMP_TMPANDLOCKDIR:-$DEFAULT__MYSQLDUMP_TMPANDLOCKDIR}"
  export MYSQLDUMP_EXCLUSIVELOCK="${MYSQLDUMP_EXCLUSIVELOCK:-$DEFAULT__MYSQLDUMP_EXCLUSIVELOCK}"

  # Other
  export SKIP_CREATE_LOCAL_FOLDERS="${SKIP_CREATE_LOCAL_FOLDERS:-$DEFAULT__SKIP_CREATE_LOCAL_FOLDERS}"
  export CREATE_LOCAL_FOLDERS_PERMISSIONS="${CREATE_LOCAL_FOLDERS_PERMISSIONS:-$DEFAULT__CREATE_LOCAL_FOLDERS_PERMISSIONS}"
  export SKIP_MYSQLDUMP="${SKIP_MYSQLDUMP:-$DEFAULT__SKIP_MYSQLDUMP}"
  export SKIP_WEBAPP_TYPE_AUTODETECTION="${SKIP_WEBAPP_TYPE_AUTODETECTION:-$DEFAULT__SKIP_WEBAPP_TYPE_AUTODETECTION}"
  export SKIP_CHECK_DONT_RUN_AS_ROOT_LOCALLY="${SKIP_CHECK_DONT_RUN_AS_ROOT_LOCALLY:-$DEFAULT__SKIP_CHECK_DONT_RUN_AS_ROOT_LOCALLY}"

  export DRYRUN="${DRYRUN:-$DEFAULT__DRYRUN}"

  if [ -n "$DRYRUN" ]; then
    export DOWNLOAD_RSYNC_DRYRUN_STRING="--dry-run"
  fi
}

################################  Functions, END ###############################