# securebox-ad-hoc-backups-for-web-applications v2.0
[draft] Portable Public Domain POSIX shell scripts for human triggered local secure backups with auto-detection features for remote web applications

In short. the securebox-ad-hoc-backups-for-web-applications v2.0 helps who have
to manage quick local backups for a lot of remote web applications, with the
bare minimum need of point to an source host (requires you already authorized
to SSH on server) and the base path of the application. Database options can
be inferred from common CMS configurations, so you don't need to specify extra
credentials.

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

## License
Public Domain