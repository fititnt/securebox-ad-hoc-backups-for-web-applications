<?php
/* REFERENCE: https://github.com/moodle/moodle/blob/master/config-dist.php */

unset($CFG);  // Ignore this line
global $CFG;  // This is necessary here for PHPUnit execution
$CFG = new stdClass();

$CFG->dbtype    = 'mariadb';    // 'pgsql', 'mariadb', 'mysqli', 'sqlsrv' or 'oci'
$CFG->dblibrary = 'native';     // 'native' only at the moment
$CFG->dbhost    = 'localhost';  // eg 'localhost' or 'db.isp.com' or IP
$CFG->dbname    = 'moodle';     // database name, eg moodle
$CFG->dbuser    = 'username';   // your database username
$CFG->dbpass    = 'password';   // your database password
$CFG->prefix    = 'mdl_';       // prefix to use for all table names
$CFG->dboptions = array(
    'dbpersist' => false,       // should persistent database connections be
                                //  used? set to 'false' for the most stable
                                //  setting, 'true' can improve performance
                                //  sometimes
    'dbsocket'  => false,       // should connection via UNIX socket be used?
                                //  if you set it to 'true' or custom path
                                //  here set dbhost to 'localhost',
                                //  (please note mysql is always using socket
                                //  if dbhost is 'localhost' - if you need
                                //  local port connection use '127.0.0.1')
    'dbport'    => '',          // the TCP port number to use when connecting
                                //  to the server. keep empty string for the
                                //  default port
    'dbhandlesoptions' => false,// On PostgreSQL poolers like pgbouncer don't
                                // support advanced options on connection.
                                // If you set those in the database then
                                // the advanced settings will not be sent.
    'dbcollation' => 'utf8mb4_unicode_ci', // MySQL has partial and full UTF-8
 
  // For all database config settings see https://docs.moodle.org/en/Database_settings
);

$CFG->wwwroot   = 'http://example.com/moodle';
$CFG->dataroot  = '/home/example/moodledata';
$CFG->directorypermissions = 02777;
$CFG->admin = 'admin';

require_once(__DIR__ . '/lib/setup.php'); // Do not edit
