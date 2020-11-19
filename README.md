# Securebox ad hoc backups for web applications v4.0
**Human aided remote web application backup to an local "securebox" workstation.
Auto discovery features (like databases to dump) from common web apps
configuration files: it means you may actually not need much more than specify
an SSH host and the path of the application.** Written in a very portable POSIX
shell script. Dedicated to Public Domain.

**Quick usage**:

`securebox-backup-download` is designed to **not** need configuration files,
neither require root access or be installed on a remote host. If you can
`ssh user@example.org`, you can do this:
```bash
SOURCE_HOST="user@example.org" securebox-backup-download
# user@example.org:/var/www files are rsync'ed to /backups/mirror/default/default/files
```

**Smart autodiscovery of typical web applications**

One of the main advantages of `securebox-backup-download` over plain rsync is
the smart discover of common web applications. On this example you don't need to
specify the `SOURCE_MARIADB_DBNAME`, `SOURCE_MARIADB_USER` and
`SOURCE_MARIADB_PASS`... and still works!

```bash
SOURCE_HOST="joomlauser@example.org" SOURCE_PATH="/var/www/joomla/" securebox-backup-download
# example.org:/var/www/joomla are rsync'ed  to /backups/mirror/default/default/files
# Database mentioned on /var/www/joomla/configuration.php will be at /backups/mirror/default/default/mysqldump/dbname.sql
```

See [Quickstart](#quickstart) to check if you like the idea. Then look at the
[Installation](#installation).

---

**Table of Contents**

<!-- TOC depthFrom:2 -->

- [Usage](#usage)
    - [Quickstart](#quickstart)
        - [Minimal usage](#minimal-usage)
        - [With configuration files](#with-configuration-files)
    - [General idea of how it works](#general-idea-of-how-it-works)
    - [Frequent Asked Questions](#frequent-asked-questions)
        - [1. Timeouts on MariaDB/MySQL with very large database dumps](#1-timeouts-on-mariadbmysql-with-very-large-database-dumps)
        - [2. '/tmp/databasedump.lock' lock issues / Why do I have to delete manually?](#2-tmpdatabasedumplock-lock-issues--why-do-i-have-to-delete-manually)
- [Internals](#internals)
    - [List of auto discovered web applications](#list-of-auto-discovered-web-applications)
        - [Joomla](#joomla)
        - [Laravel](#laravel)
        - [Moodle](#moodle)
    - [Strategies](#strategies)
        - [Files management](#files-management)
            - [rsync](#rsync)
        - [Database management](#database-management)
            - [MariaDB/MySQL - mysqldump](#mariadbmysql---mysqldump)
    - [Extend Securebox Backups](#extend-securebox-backups)
        - [Quickstart on how to add a new application (using as reference Joomla CMS)](#quickstart-on-how-to-add-a-new-application-using-as-reference-joomla-cms)
- [Design choises](#design-choises)
    - [Why Securebox Ad Hoc Backups is different](#why-securebox-ad-hoc-backups-is-different)
        - [Agentless, zero-installation, automatic discovery of remote web applications without root](#agentless-zero-installation-automatic-discovery-of-remote-web-applications-without-root)
        - [Don't need open ports of database servers to save a copy locally](#dont-need-open-ports-of-database-servers-to-save-a-copy-locally)
        - [No special dependencies requeriments on remote server](#no-special-dependencies-requeriments-on-remote-server)
        - [Simple installation on local workstation with zero to none extra dependency requirements](#simple-installation-on-local-workstation-with-zero-to-none-extra-dependency-requirements)
            - [Exceptions on advanced cases](#exceptions-on-advanced-cases)
        - [Concept of `ORGANIZATION` and `PROJECT` and to `SUBDIR_*` to simplify defaults](#concept-of-organization-and-project-and-to-subdir_-to-simplify-defaults)
            - [Why we may choose to not make it even more configurable than `ORGANIZATION` + `PROJECT` + `SUBDIR_*`](#why-we-may-choose-to-not-make-it-even-more-configurable-than-organization--project--subdir_)
            - [Why we choose do archive entire folders, even if tools like mysqldump export single file](#why-we-choose-do-archive-entire-folders-even-if-tools-like-mysqldump-export-single-file)
- [Installation](#installation)
    - [Android](#android)
        - [Android installation with Termux](#android-installation-with-termux)
    - [Linux](#linux)
        - [Generic Linux Installation](#generic-linux-installation)
        - [Tails installation](#tails-installation)
    - [Windows](#windows)
        - [Windows Subsystem for Linux installation](#windows-subsystem-for-linux-installation)
- [Variables reference](#variables-reference)
    - [Most used variables](#most-used-variables)
        - [`ORGANIZATION`](#organization)
        - [`PROJECT`](#project)
        - [`SOURCE_HOST`](#source_host)
        - [`SOURCE_PATH`](#source_path)
    - [Extra variables](#extra-variables)
        - [`LOCALARCHIVES_BASEPATH`](#localarchives_basepath)
        - [`LOCALMIRROR_BASEPATH`](#localmirror_basepath)
        - [`LOCALTMP`](#localtmp)
        - [`SOURCE_MARIADB_DBNAME`](#source_mariadb_dbname)
        - [`SOURCE_MARIADB_HOST`](#source_mariadb_host)
        - [`SOURCE_MARIADB_PASS`](#source_mariadb_pass)
        - [`SOURCE_MARIADB_USER`](#source_mariadb_user)
        - [`SUBDIR_FILES`](#subdir_files)
        - [`SUBDIR_MYSQLDUMP`](#subdir_mysqldump)
    - [Variables to disable skip (disable) internal steps](#variables-to-disable-skip-disable-internal-steps)
        - [`SKIP_CHECK_DONT_RUN_AS_ROOT_LOCALLY`](#skip_check_dont_run_as_root_locally)
        - [`SKIP_DOWNLOAD_RSYNC`](#skip_download_rsync)
        - [`SKIP_MYSQLDUMP`](#skip_mysqldump)
        - [`SKIP_WEBAPP_TYPE_AUTODETECTION`](#skip_webapp_type_autodetection)
    - [Reserved variables](#reserved-variables)
        - [`TARGET_HOST`](#target_host)
        - [`TARGET_MARIADB_DBNAME`](#target_mariadb_dbname)
        - [`TARGET_MARIADB_HOST`](#target_mariadb_host)
        - [`TARGET_MARIADB_PASS`](#target_mariadb_pass)
        - [`TARGET_MARIADB_USER`](#target_mariadb_user)
        - [`TARGET_PATH`](#target_path)
- [License](#license)

<!-- /TOC -->

---

## Usage

### Quickstart

#### Minimal usage

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

#### With configuration files

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

### General idea of how it works

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

### Frequent Asked Questions
> Note: most of the FAQ here cover issues that you could have even without using
  the Securebox Ad Hoc Backups in special on new workstation. Since one of the
  goals of this project is work even on Live Operational Systems (or people
  who do not typicaly use CLI tools), we will mention them to save you time.

#### 1. Timeouts on MariaDB/MySQL with very large database dumps
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

#### 2. '/tmp/databasedump.lock' lock issues / Why do I have to delete manually?
> `MYSQLDUMP_EXCLUSIVELOCK=` (empty) change this intentional behavior

The `/tmp/databasedump.lock` (MYSQLDUMP_TMPANDLOCKDIR) is both a temporary dir
and a lock mechanism (it means you don't overload your server with multiple
runs). It's intentional to require the user to manually delete instead of do it.

This issue is likely to happen if you last attempt timeouted (see FAQ 1).

## Internals

### List of auto discovered web applications
Note: as v3.0 only files and MariaDB/MySQL databases are implemented on
web applications auto detected. Other databases (like PostgreSQL)you know how to
translate an `mysqldump` command to another tool, can be _easily_ added.

#### Joomla
> Since v1.0

#### Laravel
> Since v3.0

#### Moodle
> Since 3.0

### Strategies

#### Files management

##### rsync

#### Database management

##### MariaDB/MySQL - mysqldump

### Extend Securebox Backups
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
- #### Similar app already have strategy I need
If some web application on this list already is know to backup an item your
target 

To implement auto


so, in worst case
scenario, it will not just detect how to automatically do extra steps, like
dum
-->

## Design choises

### Why Securebox Ad Hoc Backups is different

#### Agentless, zero-installation, automatic discovery of remote web applications without root
Securebox Ad Hoc Backups don't need to be installed on remote server. It
actually make things even simpler.

In short, if runs `rsync` commands to mirror remote files on your local
workstation. Then, based on the local copy, if detect that is part of the
[List of auto discovered web applications](#list-of-auto-discovered-web-applications)
it will try additional apply extra [Strategies](#strategies) for this specific
software over ssh and then copy to local using rsync.

#### Don't need open ports of database servers to save a copy locally

> TODO: ...

#### No special dependencies requeriments on remote server
As long as you can use SSH (plain FTP will not work; but "SFTP/SCP" may already
be _another name_ for SSH) even average shared cheap web hosting are likely to
already have everyting you need.

For file transfer, we use `rsync`. When have to execute an remote command, like
dump a file that can be downloaded to local workstation, we use
`ssh user@example.org 'db-command export mydb > file.sql'`.

As reference, the "db-command" for MariaDB/MySQL is `mysqldump`, a tool that
already often is already installed on MariaDB/MySQL clients/servers.

New strategies, for sake of simplicitly and portability, are also likely to use
also common tools. Like `pg_dump` for PostgreSQL, `mongodump` MongoDB.

#### Simple installation on local workstation with zero to none extra dependency requirements
While be easy to install does not make Securebox Ad Hoc Backups really different
from alternatives, on very specific cases this is a life saver. For example,
`mongodump` is know to complain if the version of mongodump and the server
are different, and if you work with many different projects it would be not
practical have all then installed locally.

The bare minimum requeriments are `ssh` and (something that may not installed
on some nearly initialized operational systems) the `rsync` command. You also
need be able to connect from `ssh`/`rsync` from your machine to the remote host.
With only these requeriments, the `securebox-backup-download` already will be
able to make a full copy of remote applications mirroed to your local
workstation. Even the database exports (and in the furure, imports) are done
only on remote servers, so you don't even need `mysqldump` / `pg_dump` /
`mongodump` / etc installed.

##### Exceptions on advanced cases

`securebox-backup-archive-locally` (to compress/encrypt) and
`securebox-backup-archive-s3` (to upload to S3 compatible servers) are likely
to need some extra dependencies on the Securebox workstation if you want more
than just mirror of remote application.

Note: if somewhat becomes possible to not even install s3cmd and just upload
to S3 using plain shell script, we may choose to implement this! See
[issues#2](https://github.com/fititnt/securebox-ad-hoc-backups-for-web-applications/issues/2).

#### Concept of `ORGANIZATION` and `PROJECT` and to `SUBDIR_*` to simplify defaults

Securebox backups whatever is your current task, at least for local processing,
works with the concept of `ORGANIZATION` and `PROJECT`. If you do not set one
of these they will default to _default_ and _default_ . **This design choice is
not necessarily an advantage over alternatives, because is... well,
opinionated**. But it simplifies the ad hoc usagle without configuration files.
This also makes easier to add and (this takes lots of time) document some
planned advanced functionality (like allow mount/umount encrypted volumes
before/after running Securebox Backups).

Less obvious, but still pertinent, is the concept of `SUBDIR_*` (as v3.0 only
`SUBDIR_FILES="files"` and `SUBDIR_MYSQLDUMP="mysqldump"`). See the following
example:

> - `$LOCALMIRROR_BASEPATH/$ORGANIZATION/$PROJECT`: Contain all mirrored data
>   - `/backups/mirror/default/default`
> - `$LOCALMIRROR_BASEPATH/$ORGANIZATION/$PROJECT/$SUBDIR_FILES`: rsync'ed files
>   - `/backups/mirror/default/default/files`
> - `$LOCALMIRROR_BASEPATH/$ORGANIZATION/$PROJECT/$SUBDIR_MYSQLDUMP`: mysqldump result for current project
>   - `/backups/mirror/default/default/mysqldump`

The default (yet configurable) name `files` is the mirrored rsync. The
`mysqldump` name was used instead of mariadb/mysql because do exist tools like
[mydumper](https://github.com/maxbube/mydumper) and they generate not the same
output. So the `SUBDIR_*` is used to help with evolution over the years to mix
different types of output and still be backwards compatible. Maybe even like 10
or 20 years.

##### Why we may choose to not make it even more configurable than `ORGANIZATION` + `PROJECT` + `SUBDIR_*`
While you are free to make your own fork to fit better your needs and publish
for the rest of the world, things that could over complicate the Ad Hoc usage
(without configuration file) or (not really an priority, but may be pertinent)
add too much extra code **and could not work by just adding an extra
`SUBDIR_*`**, we may choose to not implement.

**Breaking complex issues in smaller tasks**

Depending of how complex is some of your user cases, it may be pertinent to
create two tasks. For example, our [Moodle](#moodle) driver is able to do full
mirroring if both `moodle` (Application code) and `moodledata` (application
"downloads", they are files on disk, not on database) **if the layout is somewhat
specific**. If you try to use this project on a client that do not follow this
pattern you may need to use one task to download only the moodle (Application
code) and the database, and another task just do download the `moodledata`.

On the very specific case of Moodle, actually the `moodle` (Application code)
don't change as often as the `moodledata` + the database itself so even if use
this tool on cron instead of Ad Hoc, would still makes sense not backup that
often the `moodle` (Application code). Be creative!

##### Why we choose do archive entire folders, even if tools like mysqldump export single file
To make things simpler tools who archive either locally or upload for a service
like S3 will do the entire folder. This cut a lot of code and make easier to
extend and also make easier to make recover more predictable at long term. This
could even allow add some README.txt as part of the backup tool with extra
instructions!

Instead of change the behavior of this tool (even for a private fork) just
because of this part consider the following: when recovering archived files
just add an extra line on your script to uncompress the file from the folder.

## Installation

### Android
#### Android installation with Termux
- [Termux on Google Play](https://play.google.com/store/apps/details?id=com.termux&hl=pt_BR&gl=US)

The well documented file that explain how to both boostrap an newly installed
Termux and how to install the Securebox is at
[extras/securebox-termux-full-setup.sh](extras/securebox-termux-full-setup.sh).


**[Recommended] 4 steps: download, review, execute, and (if worked) delete the installer**

```bash
curl https://raw.githubusercontent.com/fititnt/securebox-ad-hoc-backups-for-web-applications/main/extra/securebox-termux-full-install.sh --output ~/securebox.sh
cat ~/securebox.sh
sh ~/securebox.sh
rm ~/securebox.sh
```

**[Not recommended] One-liner installer**

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/fititnt/securebox-ad-hoc-backups-for-web-applications/main/extra/securebox-termux-full-install.sh)"
```

### Linux
#### Generic Linux Installation

> TODO: document how to install on Generic Linux (fititnt, 2020-11-19 05:15 UTC)

#### Tails installation

> TODO: document how to install on Tails (fititnt, 2020-11-19 05:15 UTC)

### Windows
#### Windows Subsystem for Linux installation
- See [Windows Subsystem for Linux Installation Guide for Windows 10](https://docs.microsoft.com/windows/wsl/install-win10)

## Variables reference

<!--
Internal note: we can use https://sortmylist.com/ to autosort the names.
-->

### Most used variables
#### `ORGANIZATION`
- Since: v1.0
#### `PROJECT`
- Since: v1.0
#### `SOURCE_HOST`
- Since: v1.0
#### `SOURCE_PATH`
- Since: v1.0

### Extra variables

#### `LOCALARCHIVES_BASEPATH`
- Since: v2.0
#### `LOCALMIRROR_BASEPATH`
- Since: v2.0
#### `LOCALTMP`
- Since: v2.0
#### `SOURCE_MARIADB_DBNAME`
- Since: v2.0
#### `SOURCE_MARIADB_HOST`
- Since: v2.0
#### `SOURCE_MARIADB_PASS`
- Since: v2.0
#### `SOURCE_MARIADB_USER`
- Since: v2.0
#### `SUBDIR_FILES`
- Since: v2.0
#### `SUBDIR_MYSQLDUMP`
- Since: v2.0

### Variables to disable skip (disable) internal steps
> Note: these variables are subject to renaming. Since they we're not documented
until 3.0+, we may choose to not explain migration steps.

#### `SKIP_CHECK_DONT_RUN_AS_ROOT_LOCALLY`
#### `SKIP_DOWNLOAD_RSYNC`
#### `SKIP_MYSQLDUMP`
#### `SKIP_WEBAPP_TYPE_AUTODETECTION`

### Reserved variables
These variables are planned, but not implemented.

#### `TARGET_HOST`
#### `TARGET_MARIADB_DBNAME`
#### `TARGET_MARIADB_HOST`
#### `TARGET_MARIADB_PASS`
#### `TARGET_MARIADB_USER`
#### `TARGET_PATH`

## License
[![Public Domain](https://i.creativecommons.org/p/zero/1.0/88x31.png)](UNLICENSE)

To the extent possible under law, [Emerson Rocha](https://github.com/fititnt)
has waived all copyright and related or neighboring rights to this work to
[Public Domain](UNLICENSE).

<!--
Boring links for _why_ 0BSD is added as alternative to The Unlicense.

- http://landley.net/toybox/license.html
- http://landley.net/toybox/0bsd-mckusick.txt
- https://en.wikipedia.org/wiki/Public-domain-equivalent_license
-->

As alternative (_"Unlicense OR 0BSD"_; choose and use the license of
your needs) this project is also released with the Open Source Initiative
approved [Zero-Clause BSD](https://opensource.org/licenses/0BSD) License.

> SPDX-License-Identifier: Unlicense OR 0BSD