# securebox-ad-hoc-backups-for-web-applications v3.0 (draft)
**Portable Public Domain POSIX shell scripts for human triggered local secure
backups with auto-detection features for remote web applications**

In short: the securebox-ad-hoc-backups-for-web-applications v2.0 helps who have
to manage quick local backups for a lot of remote web applications, with the
bare minimum need of point to an source host (requires you already authorized
to SSH on server) and the base path of the application. Database options can
be inferred from common CMS configurations, so you don't need to specify extra
credentials.

---

**Table of Contents**

<!-- TOC depthFrom:2 -->

- [Supported web applications](#supported-web-applications)
    - [Joomla](#joomla)
    - [Moodle](#moodle)
- [Already implemented features](#already-implemented-features)
- [Changelog (the first public version)](#changelog-the-first-public-version)
- [FAQ](#faq)
    - [1. Timeouts on MariaDB/MySQL large database dumps](#1-timeouts-on-mariadbmysql-large-database-dumps)
    - [2. '/tmp/databasedump.lock' lock issues / Why do I have to delete manually?](#2-tmpdatabasedumplock-lock-issues--why-do-i-have-to-delete-manually)
- [License](#license)

<!-- /TOC -->

---

## Supported web applications

Note: as v3.0 (draft) only files and MariaDB/MySQL databases are implemented on
web applications auto detected. Other databases (like PostgreSQL) as long as
you how to translate an `mysqldump` command to another tool, can be _easily_
added.

### Joomla
> Since v1.0

### Moodle
> Since 3.0 (draft)


## Already implemented features

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
> `MYSQLDUMP_EXCLUSIVELOCK=` (empty) change this **intentional** behavior

The `/tmp/databasedump.lock` (`MYSQLDUMP_TMPANDLOCKDIR`) is both an temporary
dir and a lock mecanism (it means you don't overload your server with multiple
runs). It's intentional require the user to manually delete instead of do it.

This issue is likely to happens if you last atempt timeout'ed (see FAQ 1).

## License
Public Domain