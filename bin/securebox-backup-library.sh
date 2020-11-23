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
#       LICENSE:  Public Domain / Zero-Clause BSD
#                 SPDX-License-Identifier: Unlicense OR 0BSD
#       VERSION:  v2.1
#       CREATED:  2020-11-14 23:52 UTC Created. Based on securebox-backup-download v2.0
#      REVISION:  2020-11-16 05:06 UTC Autodetect Moodle LMS configurations
#                 2020-11-23 11:33 UTC v4.0 version bump. Code refactoring started.
#                                      See GitHub GitHub & docs for details
#===============================================================================
export SECUREBOX_BACKUP_LIBRARY_VERSION="4.0.0"

################# Example of user configurable variables, START ################
# Maybe we dont use this


# SECUREBOX_MIRROR="$SECUREBOX/mirror"
# SECUREBOX_SNAPSHOTS="$SECUREBOX/snapshots"
# SECUREBOX_TMP="$SECUREBOX/tmp"

################# Example of user configurable variables, END ##################

# TODO: document some tricks to workaround timeout issues when dumping large
#       databases. https://www.tecmint.com/increase-ssh-connection-timeout/
#       Maybe instruct person to open a second ssh connection while using this
#       tool could be a quick ad hoc workaround?
#       (fititnt, 2020-11-16 02:04 BRT)

# TODO: implement some kind of quick check to see if user is able to ssh to the
#       remote server. Maybe as part of the initial setup or when first rsync
#       fails (fititnt, 2020-11-16 01:02 BRT)

# TODO: implement some feature, like explicitly set a relative path to an CMS
#       type that not only would skip securebox_common_options_project() checks
#       but already define the strategy to use. Maybe
#           WEBAPP_JOOMLA_CONFIGURATION="path/to/configuration"
#           WEBAPP_MOODLE_CONFIG="path/to/config.php"
#           WEBAPP_WORDPRESS_WPCONFIG="path/to/wp-config.php"
#       (fititnt, 2020-11-16 01:07 BRT)

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

# @see securebox_common_options_setdefaults_base()
export DEFAULT__SECUREBOX="/backups"
# export DEFAULT__SECUREBOX_MIRROR="$SECUREBOX/mirror"
# export DEFAULT__SECUREBOX_SNAPSHOTS="$SECUREBOX/snapshots"
# export DEFAULT__SECUREBOX_TMP="$SECUREBOX/tmp"
# SECUREBOX_MIRROR="$SECUREBOX/mirror"
# SECUREBOX_SNAPSHOTS="$SECUREBOX/snapshots"
# SECUREBOX_TMP="$SECUREBOX/tmp"

# export DEFAULT__LOCALMIRROR_BASEPATH="/backups/mirror"
# export DEFAULT__LOCALARCHIVES_BASEPATH="/backups/archives"
# export DEFAULT__LOCALTMP="/backups/tmp"
# export DEFAULT__SUBDIR_FILES="files" # /backups/mirror/default/default/files/...
# export DEFAULT__SUBDIR_MYSQLDUMP="mysqldump" # /backups/mirror/default/default/mysqldump/dbname.sql
# DEFAULT__LOCALMIRROR_THISPROJECT="$DEFAULT__SECUREBOX_MIRROR/$DEFAULT__ORGANIZATION/$DEFAULT__PROJECT"

export DEFAULT__DOWNLOAD_RSYNC_EXCLUDES="--exclude='.well-known'"
export DEFAULT__DOWNLOAD_RSYNC_EXTRAOPTIONS=""

# This path is both for temporary files AND to, if you run this script too fast
# will not allow run again.
export DEFAULT__MYSQLDUMP_TMPANDLOCKDIR="/tmp/databasedump.lock"
export DEFAULT__MYSQLDUMP_EXCLUSIVELOCK="1"

# This script will atempt to create some local paths if they already do not exist
# You can define DEFAULT__SKIP_CREATE_LOCAL_FOLDERS=1 to create yourself
export DEFAULT__SKIP_CREATE_LOCAL_FOLDERS=
export DEFAULT__SECUREBOX_MKDIR_MODE="0711"
# export DEFAULT__SECUREBOX_MKDIR_MODE="0711"

export DEFAULT__SKIP_DOWNLOAD_RSYNC

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

    # SECUREBOX_MIRROR [$SECUREBOX_MIRROR]
    sudo mkdir /backups/mirror
    sudo chmod 777 /backups/mirror
    sudo chown root:root /backups/mirror

    # LOCALARCHIVES_BASEPATH [$LOCALARCHIVES_BASEPATH]
    sudo mkdir /backups/snapshots
    sudo chmod 777 /backups/snapshots
    sudo chown root:root /backups/snapshots

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

  _local_versions=$(env | sort | grep '^SECUREBOX')

  # printf "========== securebox_common_debug, start ==========\n"
  printf "\nGeneral\n"
  echo "  ORGANIZATION: $ORGANIZATION"
  echo "  PROJECT: $PROJECT"
  echo "  SECUREBOX: $SECUREBOX"
  #echo "    SECUREBOX_MIRROR: $SECUREBOX_MIRROR"
  #echo "      SECUREBOX_MIRROR_NOW: $SECUREBOX_MIRROR_NOW"
  #echo "    SECUREBOX_SNAPSHOTS: $SECUREBOX_SNAPSHOTS"
  #echo "      SECUREBOX_SNAPSHOTS_NOW: $SECUREBOX_SNAPSHOTS_NOW"
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
  #echo "  SECUREBOX_MIRROR: $SECUREBOX_MIRROR"
  #echo "  LOCALMIRROR_THISPROJECT: $LOCALMIRROR_THISPROJECT"

  echo "$_local_versions"

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

  # Only check if file first argument is an file if is not an typical help argument
  if [ "$_localvar_cliopt1" ] &&
    [ "$_localvar_cliopt1" != "-h" ] &&
    [ "$_localvar_cliopt1" != "--help" ] &&
    [ "$_localvar_cliopt1" != "--help-bootstrap" ]; then
  
    if [ -f "$_localvar_cliopt1" ]; then
      test "${DEBUG}" = "1" && echo "securebox_common_options_securebox_confs:"
      echo "  [$_localvar_cliopt1] exists. Sourcing now"

      if [ "$(tr -cd '\r' < "$_localvar_cliopt1" | wc -c)" -gt 0 ]; then
        test "${DEBUG}" = "1" && echo "securebox_common_options_securebox_confs:"
        echo "  The file seems to have CRLF instead of LF as line endings"
        echo "  This may break things very, VERY bad. Refusing to continue"
        echo "  Please fix with something like"
        echo "      dos2unix $_localvar_cliopt1"
        echo "Aborting now."
        exit 2
      fi
      # shellcheck source=/dev/null
      . "$_localvar_cliopt1"
    else
      echo "securebox_common_options_securebox_confs:"
      echo "ERROR! [$_localvar_cliopt1] (first cli argument) is not an readable config file"
      echo "    $PROGRAM_NAME --help"
      echo "Aborting now."
      exit 2
    fi
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
  # POSIX does support local keywork.
  _local_root="$SECUREBOX_MIRROR_NOW/$SUBDIR_FILES"


  # Joomla?
  if [ -f "${_local_root}/configuration.php" ]; then
    echo "securebox_options_inferece_from_project: trying Joomla [${_local_root}/configuration.php]..."
    securebox_common_options_project_joomla "${_local_root}/configuration.php"
    return
  fi

  # Wordpress?
  if [ -f "${_local_root}/wp-config.php" ]; then
    echo "securebox_options_inferece_from_project: trying Wordpress [${_local_root}/wp-config.php]..."
    securebox_common_options_project_wordpress "${_local_root}/wp-config.php"
    return
  fi

  # Laravel?
  if [ -f "${_local_root}/artisan" ]; then
    echo "securebox_options_inferece_from_project: [${_local_root}/artisan] exists. Laravel?"
    if [ -f "${_local_root}/.env" ]; then
      echo "securebox_options_inferece_from_project: trying Laravel [${_local_root}/.env]..."
      securebox_common_options_project_laravel "${_local_root}/.env"
    fi
    return
  fi

  # Moodle?
  if [ -f "${_local_root}/config.php" ]; then
    echo "securebox_options_inferece_from_project: trying Moodle [${_local_root}/config.php]..."
    securebox_common_options_project_moodle "${_local_root}/config.php"
  elif [ -f "${_local_root}/moodle/config.php" ]; then
    echo "securebox_options_inferece_from_project: trying Moodle [${_local_root}/moodle/config.php]..."
    securebox_common_options_project_moodle "${_local_root}/moodle/config.php"
  else
    echo "securebox_options_inferece_from_project: Web Application type not automatically detected" 
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
# Parse an typical Laravel .env file and export variables
# See https://github.com/laravel/laravel/blob/8.x/.env.example
# Globals:
#   SOURCE_MARIADB_DBNAME
#   SOURCE_MARIADB_HOST
#   SOURCE_MARIADB_USER
#   SOURCE_MARIADB_PASS
# Arguments:
#   /path/to/laravel/.env
# Returns:
#   None
#######################################
securebox_common_options_project_laravel ()
{

  _local_con=$(awk -F "=" '/DB_CONNECTION/ {print $2}' "$1")

  if [ "$_local_con" != "mysqlaa" ]; then
    echo "securebox_common_options_project_laravel"
    echo "  WARNING: [$_local_con] does not seems to be MariaDB/MySQL. Continuing anyway"
  fi

  SOURCE_MARIADB_DBNAME=$(awk -F "=" '/DB_DATABASE/ {print $2}' "$1")

  _local_dbhost=$(awk -F "=" '/DB_HOST/ {print $2}' "$1")
  _local_dbport=$(awk -F "=" '/DB_PORT/ {print $2}' "$1")

  SOURCE_MARIADB_HOST="${_local_dbhost}${_local_dbport-3306}"

  SOURCE_MARIADB_USER=$(awk -F "=" '/DB_USERNAME/ {print $2}' "$1")
  SOURCE_MARIADB_PASS=$(awk -F "=" '/DB_PASSWORD/ {print $2}' "$1")

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
  # echo 'oioi'
  # # securebox_backup_download_help
  # awk -F"'" '/dbhost/{print $2}' "$1"
  # awk -F"'" '/dbname/{print $2}' "$1"
  # awk -F"'" '/dbuser/{print $2}' "$1"
  # awk -F"'" '/dbpass/{print $2}' "$1"

  # grep -oP "\\db\s.+?'\K[^']+" "$1"
  # echo 'oioi 2'
  SOURCE_MARIADB_DBNAME=$(awk -F"'" '/dbname/{print $2}' "$1")
  SOURCE_MARIADB_HOST=$(awk -F"'" '/dbhost/{print $2}' "$1")
  SOURCE_MARIADB_USER=$(awk -F"'" '/dbuser/{print $2}' "$1")
  SOURCE_MARIADB_PASS=$(awk -F"'" '/dbpass/{print $2}' "$1")

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

  # auto detect better alternatives to DEFAULT__SECUREBOX="/backups"
  if [ -z "$SECUREBOX" ]; then
    securebox_common_options_setdefaults_base
  fi

  ## About this project
  export ORGANIZATION="${ORGANIZATION:-$DEFAULT__ORGANIZATION}"
  export PROJECT="${PROJECT:-$DEFAULT__PROJECT}"
  export WEBAPP_TYPE="${WEBAPP_TYPE:-$DEFAULT__WEBAPP_TYPE}"
  export LOCALTMP="${LOCALTMP:-$DEFAULT__LOCALTMP}"
  export SECUREBOX_MIRROR="${SECUREBOX_MIRROR:-$SECUREBOX/mirror}"
  export SECUREBOX_MIRROR_NOW="${SECUREBOX_MIRROR_NOW:-$SECUREBOX_MIRROR/$ORGANIZATION/$PROJECT}"
  export SECUREBOX_MIRROR_NOW_DRIVER_FILES="${SECUREBOX_MIRROR_NOW}/files"
  export SECUREBOX_MIRROR_NOW_DRIVER_MYSQLDUMP="${SECUREBOX_MIRROR_NOW}/mysqldump"
  export SECUREBOX_SNAPSHOTS="${SECUREBOX_SNAPSHOTS:-$SECUREBOX/snapshots}"
  export SECUREBOX_SNAPSHOTS_NOW="${SECUREBOX_SNAPSHOTS_NOW:-$SECUREBOX_SNAPSHOTS/$ORGANIZATION/$PROJECT}"
  export SECUREBOX_SNAPSHOTS_NOW_DRIVER_FILES="${SECUREBOX_SNAPSHOTS_NOW}/files"
  export SECUREBOX_SNAPSHOTS_NOW_DRIVER_MYSQLDUMP="${SECUREBOX_SNAPSHOTS_NOW}/mysqldump"
  #export  DEFAULT__LOCALMIRROR_THISPROJECT="$DEFAULT__SECUREBOX_MIRROR/$DEFAULT__ORGANIZATION/$DEFAULT__PROJECT"
  # export LOCALMIRROR_THISPROJECT="${LOCALMIRROR_THISPROJECT:-$SECUREBOX_MIRROR/$ORGANIZATION/$PROJECT}"
  # export LOCALARCHIVES_BASEPATH="${LOCALARCHIVES_BASEPATH:-$DEFAULT__LOCALARCHIVES_BASEPATH}"
  # export LOCALARCHIVES_THISPROJECT="${LOCALARCHIVES_THISPROJECT:-$LOCALARCHIVES_BASEPATH/$ORGANIZATION/$PROJECT}"
  # export SUBDIR_FILES="${SUBDIR_FILES:-$DEFAULT__SUBDIR_FILES}"
  # export SUBDIR_MYSQLDUMP="${SUBDIR_MYSQLDUMP:-$DEFAULT__SUBDIR_MYSQLDUMP}"

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
  export SKIP_DOWNLOAD_RSYNC="${SKIP_DOWNLOAD_RSYNC:-$DEFAULT__SKIP_DOWNLOAD_RSYNC}"
  export SKIP_CREATE_LOCAL_FOLDERS="${SKIP_CREATE_LOCAL_FOLDERS:-$DEFAULT__SKIP_CREATE_LOCAL_FOLDERS}"
  export SECUREBOX_MKDIR_MODE="${SECUREBOX_MKDIR_MODE:-$DEFAULT__SECUREBOX_MKDIR_MODE}"
  export SKIP_MYSQLDUMP="${SKIP_MYSQLDUMP:-$DEFAULT__SKIP_MYSQLDUMP}"
  export SKIP_WEBAPP_TYPE_AUTODETECTION="${SKIP_WEBAPP_TYPE_AUTODETECTION:-$DEFAULT__SKIP_WEBAPP_TYPE_AUTODETECTION}"
  export SKIP_CHECK_DONT_RUN_AS_ROOT_LOCALLY="${SKIP_CHECK_DONT_RUN_AS_ROOT_LOCALLY:-$DEFAULT__SKIP_CHECK_DONT_RUN_AS_ROOT_LOCALLY}"

  export DRYRUN="${DRYRUN:-$DEFAULT__DRYRUN}"

  if [ -n "$DRYRUN" ]; then
    export DOWNLOAD_RSYNC_DRYRUN_STRING="--dry-run"
  fi

  # To avoid user need to use DEBUG=1, we will print at least basic information
  # TODO: move to a dedicated function (fititnt, 2020-11-23 16:08 UTC)
  echo ""
  echo "ORGANIZATION: $ORGANIZATION"
  echo "PROJECT: $PROJECT"
  echo "SECUREBOX: $SECUREBOX"
  echo "SECUREBOX_MIRROR_NOW: $SECUREBOX_MIRROR_NOW"

  if [ "$SECUREBOX_TASKNAME" = "securebox-backup-snapshot-locally" ]; then
    echo "SECUREBOX_SNAPSHOTS_NOW: $SECUREBOX_SNAPSHOTS_NOW"
  fi

  echo ""
  echo "SOURCE_HOST: $SOURCE_HOST"
  echo "SOURCE_PATH: $SOURCE_PATH"
  echo ""
}

#######################################
# This funcion try to smart detect better values for
# DEFAULT__SECUREBOX="/backups" when the user already does not specificed
# explicitly.
# Globals:
#   ...
# Arguments:
#   None
# Returns:
#   0 if success
#   1 if error
#######################################
securebox_common_options_setdefaults_base()
{

  #### /mnt/backups
  # /mnt/backups (explicitly mounted partitio or external storage) is assumed to
  # always have priority while /backups is the lowerst one.
  if [ -d "/mnt/backups" ]; then
    export SECUREBOX="/mnt/backups"
    # echo "SECUREBOX $SECUREBOX"
    return 0
  fi

  #### ~/Persistent/backups
  # Tails is an perfect operational system for an securebox as (when
  # Persistence is enabled) you can have an USB stick already encrypted and
  # the entire operational system is safer than boot on your own daily use
  # OS. Since Tails will not persist ~/backups on reboot this will try to use
  # the folder on your persistent storage. If you are using Live Tails and
  # backuping to an external drive, please mount the /mnt/backups.
  if [ -d "$HOME/Persistent/backups" ]; then
    export SECUREBOX="$HOME/Persistent/backups"
    # echo "SECUREBOX $SECUREBOX"
    return 0
  fi

  #### ~/storage/external-1/backups
  # @see https://wiki.termux.com/wiki/Internal_and_external_storage
  # While external storage may be a bit less secure on Android (via Termux)
  # than Termux internal storage this options if focused for cases were the user
  # don't have sufficient internal space.
  if [ -d "$HOME/storage/external-1/backups" ]; then
    export SECUREBOX="$HOME/storage/external-1/backups"
    # echo "SECUREBOX $SECUREBOX"
    return 0
  fi

  #### ~/backups
  # Subfolder on user home is likely to be 'more securebox' than /backups:
  #   - Generic Linux: the user may using ecryptfs (plus maybe / full disk encryption)
  #   - Android (via Termux): Android gives some protection from other apps
  #       compared to use ~/storage/shared or ~/storage/downloads
  #   - Tails: this is likely to be RAM or temporary storage. While is safe
  #       the user should consider upload the result to some other place
  if [ -d "$HOME/backups" ]; then
    export SECUREBOX="$HOME/backups"
    # echo "SECUREBOX $SECUREBOX"
    return 0
  fi

  ### /backups
  # This is our last try. Is likely to be mounted on local / (root) partition
  # and not an removable media. It's an good idea you at least have
  # full disk encryption or mount project folders only when working with them.
  if [ -d "/backups" ]; then
    export SECUREBOX="/backups"
    # echo "SECUREBOX $SECUREBOX"
    return 0
  fi
  echo "securebox_common_options_setdefaults_base:"
  echo "WARNING: base not found. This may lead to errors. Allowing anyway..."
  return 1
}

################################  Functions, END ###############################