# Securebox ad hoc backups for web applications v3.0
**Human aided remote web application backup to an local "securebox" workstation.
Auto discovery features (like databases to dump) from common web apps
configuration files: it means you may actually not need much more than specify
an SSH host and the path of the application.** Written in a very portable POSIX
shell script. Dedicated to Public Domain.

**Quick usage**:

securebox-backup-download is designed to **not** need configuration files,
neither require root access or be installed on a remote host. If you can
`ssh user@example.org`, you can do this:
```bash
SOURCE_HOST="user@example.org" securebox-backup-download
# user@example.org:/var/www files are rsync'ed to /backups/mirror/default/default/files
```

**Smart auto detection of extra data that needs backup** (you are _granted_ it will download the _right_
database that the web app was using):

When you specify a path and, after the content was mirrored to you secure local
workstation, if `securebox-backup-library.sh` detect it's an know typical
webapp, even if you don't specify database credentials, it will
`ssh user@example.org mysqldump` and rsync back the dump. You don't even need
to open ports!

```bash
SOURCE_HOST="joomlauser@example.org" SOURCE_PATH="/var/www/joomla/" securebox-backup-download
# example.org:/var/www/joomla are rsync'ed  to /backups/mirror/default/default/files
# Database mentioned on /var/www/joomla/configuration.php will be at /backups/mirror/default/default/mysqldump/dbname.sql
```

**With configuration files**

Again: **By _philosophical goals_ the Ad Hoc means somewhat the opposite** of
the need to configure cron jobs, install extra software, etc just to make the backup
job _right now_. **If** you have want to create configuration files, this is an
way:

```bash
# securebox-backup-download load (if exists on disk) an securebox-backup.conf
# on current working directory, You can also 

tee my-securebox-backup.conf <<EOF
SOURCE_HOST="moodleuser@example.com"
SOURCE_PATH="/var/www/moodle/"
ORGANIZATION="university-acme"
PROJECT="department-of-physics-prod"
EOF

securebox-backup-download ./my-securebox-backup.conf
# Files at /backups/mirror/university-acme/department-of-physics-prod/files
# MariaDB/MySQL at /backups/mirror/university-acme/department-of-physics-prod/mysqldump/dbname.sql
```

---

**Table of Contents**

<!-- TOC depthFrom:2 -->

- [Supported web applications (for advanced automatic backup)](#supported-web-applications-for-advanced-automatic-backup)
    - [Joomla](#joomla)
    - [Laravel](#laravel)
    - [Moodle](#moodle)
    - [_Your preferred web app_](#_your-preferred-web-app_)
        - [Quickstart on how to add a new application (using as reference Joomla CMS)](#quickstart-on-how-to-add-a-new-application-using-as-reference-joomla-cms)
        - [Similar app already have strategy I need](#similar-app-already-have-strategy-i-need)
- [Already implemented features](#already-implemented-features)
- [Changelog (the first public version)](#changelog-the-first-public-version)
- [FAQ](#faq)
    - [1. Timeouts on MariaDB/MySQL large database dumps](#1-timeouts-on-mariadbmysql-large-database-dumps)
    - [2. '/tmp/databasedump.lock' lock issues / Why do I have to delete manually?](#2-tmpdatabasedumplock-lock-issues--why-do-i-have-to-delete-manually)
- [License](#license)

<!-- /TOC -->

---


## Supported web applications (for advanced automatic backup)

Note: as v3.0 only files and MariaDB/MySQL databases are implemented on
web applications auto detected. Other databases (like PostgreSQL)you know how to
translate an `mysqldump` command to another tool, can be _easily_ added.

### Joomla
> Since v1.0

### Laravel
> Since v3.0

### Moodle
> Since 3.0

### _Your preferred web app_
Since v1.0 this tool already supported backup of files. This alone can be at
least half of the work you would need, even for unknown web applications.

If your type of application already use MariaDB/MySQL, and you don't want to
automate autodetection, then in addition to the `SOURCE_HOST` and `SOURCE_PATH`
you will also to explicitly define: `SOURCE_MARIADB_DBNAME`,
`SOURCE_MARIADB_HOST`, `SOURCE_MARIADB_USER`, and `SOURCE_MARIADB_PASS`.

#### Quickstart on how to add a new application (using as reference Joomla CMS)

If you really have several projects, and think could be easier just to implement
auto detection, a quickstart would be say that, for an configuration file like
this

```php
<?php
class JConfig
{
    /* Database Settings */
    public $host = 'localhost';
    public $user = 'databaseuser';
    public $password = 'password';
    public $db = 'databasename';
}
```

You would need to use as reference one an shell code
(see https://shellhaters.org/) like this:

```bash
# https://unix.stackexchange.com/questions/230102/parse-credentials-from-php-configuration-file
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
```

If you are willing to test, you can give a sample of config file of your project
and we may help you to implement.

<!--
#### Similar app already have strategy I need
If some web application on this list already is know to backup an item your
target 

To implement auto


so, in worst case
scenario, it will not just detect how to automatically do extra steps, like
dum
-->

## Already implemented features

> This list os from the [v2.0 release](https://github.com/fititnt/securebox-ad-hoc-backups-for-web-applications/releases/tag/v2.0)
  and still not updated to v3.0 new features.

- For each "backup job", assumes the concept of user defined 
  - `ORGANIZATION` (default: `default`)
  - `PROJECT`  (default: `default`)
  - `SOURCE_HOST` (**required, show help if undefined**)
  - `SOURCE_PATH` (default: `/var/www`)
  - (other options omitted; these 4 are the most important, others can be auto
    detected)
- Mirror the remote project on local filesystem
  - `LOCALMIRROR_BASEPATH` (default: `/backups/mirror`)
    - This enviroment variable controls the base path for backup jobs
  - Typical path `/backups/mirror/organization-a/project-b`
    - `/backups/mirror/organization-a/project-b/files`
      - Store rsync'ed files from remote project
    - `/backups/mirror/organization-a/project-b/mysqldump`
      - Store an mirrored copy, with 'mysqldump strategy', of remote project
- Autodetect common CMS web applications
  - **The web application configuration file is parsed, so if, for example
    MariaDB/MySQL options are auto-discovered, the tool will atempt to also
    mirror the database.**
  - As v2.0 the only implemented is Joomla! CMS
  - Wordpress and Moodle are drafted
- Next backup jobs are faster, and optmized require only differential
  transference of data from remote project to your local host.
  - Note: this feature may depend on significant extra storage from your local
    disk, in special for database dumps.
    - You can decide to archive the mirrored database to save space, but this
      is not the default behavior since rsync requires the uncompresed .sql
      files

## Changelog (the first public version)
This is the first public version of securebox-ad-hoc-backups-for-web-applications.
Work is based on previous (not yet released work):

> - securebox-backup-download v2.0
> - securebox-backup-library.sh v2.0
> - securebox-backup-archive-locally v1.0 (draft)

## FAQ
### 1. Timeouts on MariaDB/MySQL large database dumps
> Quick fix: while running this tool, also open an additional SSH connection to
your server. This keeps the connection alive without extra changes on your
current workstation.

When doing non-interactive _mysqldump strategy_ on a remote server is likely that for very large databases
large databases this program may timeout. The [_DB.SE Will a mysql db import
be interrupted if my ssh session times out?_](https://dba.stackexchange.com/questions/140565/will-a-mysql-db-import-be-interrupted-if-my-ssh-session-times-out) or the
[How to Increase SSH Connection Timeout in Linux](https://www.tecmint.com/increase-ssh-connection-timeout/)
may explain better this issue, but the proposed quick fix is likely to be an
win-win

_TODO: maybe we warn the user when we detect the error? This would reduce need
to document this workaround (fititnt, 2020-11-16 05:16 UTC)_

### 2. '/tmp/databasedump.lock' lock issues / Why do I have to delete manually?
> `MYSQLDUMP_EXCLUSIVELOCK=` (empty) change this intentional behavior

The `/tmp/databasedump.lock` (MYSQLDUMP_TMPANDLOCKDIR) is both a temporary dir
and a lock mechanism (it means you don't overload your server with multiple
runs). It's intentional to require the user to manually delete instead of do it.

This issue is likely to happen if you last attempt timeouted (see FAQ 1).

## License
Public Domain