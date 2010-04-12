# WARNING: this file is generated, do not edit
# 01: /home/mschout/dev/perls/5.8.8/lib/perl5/site_perl/arch/Apache/TestConfig.pm:923
# 02: /home/mschout/dev/perls/5.8.8/lib/perl5/site_perl/arch/Apache/TestConfig.pm:941
# 03: /home/mschout/dev/perls/5.8.8/lib/perl5/site_perl/arch/Apache/TestConfig.pm:1786
# 04: /home/mschout/dev/perls/5.8.8/lib/perl5/site_perl/arch/Apache/TestRun.pm:507
# 05: /home/mschout/dev/perls/5.8.8/lib/perl5/site_perl/arch/Apache/TestRunPerl.pm:84
# 06: /home/mschout/dev/perls/5.8.8/lib/perl5/site_perl/arch/Apache/TestRun.pm:725
# 07: /home/mschout/dev/perls/5.8.8/lib/perl5/site_perl/arch/Apache/TestRun.pm:725
# 08: /home/mschout/dev/apache-authcookie/t/TEST:24

package apache_test_config;

sub new {
    bless( {
                 'verbose' => undef,
                 'hostport' => 'localhost:8529',
                 'postamble' => [
                                  'TypesConfig "/home/mschout/dev/perls/5.8.8/conf/mime.types"',
                                  'Include "/home/mschout/dev/apache-authcookie/t/conf/extra.conf"',
                                  '<IfModule mod_perl.c>
    PerlPassEnv APACHE_TEST_TRACE_LEVEL
</IfModule>
',
                                  '<IfModule mod_perl.c>
    PerlSwitches -Mlib=/home/mschout/dev/apache-authcookie/t
</IfModule>
',
                                  '<IfModule mod_perl.c>
    PerlRequire /home/mschout/dev/apache-authcookie/t/conf/modperl_startup.pl
</IfModule>
',
                                  ''
                                ],
                 'mpm' => 'prefork',
                 'inc' => [
                            '/home/mschout/dev/apache-authcookie/blib/lib',
                            '/home/mschout/dev/apache-authcookie/blib/arch'
                          ],
                 'APXS' => '/home/mschout/dev/perls/5.8.8/bin/apxs',
                 '_apxs' => {
                              'LIBEXECDIR' => '/home/mschout/dev/perls/5.8.8/modules',
                              'SYSCONFDIR' => '/home/mschout/dev/perls/5.8.8/conf',
                              'TARGET' => 'httpd',
                              'BINDIR' => '/home/mschout/dev/perls/5.8.8/bin',
                              'PREFIX' => '/home/mschout/dev/perls/5.8.8',
                              'SBINDIR' => '/home/mschout/dev/perls/5.8.8/bin'
                            },
                 'save' => 1,
                 'vhosts' => {},
                 'httpd_basedir' => '/home/mschout/dev/perls/5.8.8',
                 'server' => bless( {
                                      'run' => bless( {
                                                        'conf_opts' => {
                                                                         'verbose' => undef,
                                                                         'save' => 1
                                                                       },
                                                        'test_config' => $VAR1,
                                                        'tests' => [],
                                                        'opts' => {
                                                                    'breakpoint' => [],
                                                                    'postamble' => [],
                                                                    'preamble' => [],
                                                                    'bugreport' => 1,
                                                                    'req_args' => {},
                                                                    'header' => {}
                                                                  },
                                                        'argv' => [],
                                                        'server' => $VAR1->{'server'}
                                                      }, 'Apache::TestRunPerl' ),
                                      'port_counter' => 8529,
                                      'mpm' => 'prefork',
                                      'version' => 'Apache/2.0.53',
                                      'rev' => 2,
                                      'name' => 'localhost:8529',
                                      'config' => $VAR1
                                    }, 'Apache::TestServer' ),
                 'postamble_hooks' => [
                                        'configure_inc',
                                        'configure_trace',
                                        'configure_pm_tests_inc',
                                        'configure_startup_pl',
                                        'configure_pm_tests',
                                        sub { "DUMMY" }
                                      ],
                 'inherit_config' => {
                                       'ServerRoot' => '/home/mschout/dev/perls/5.8.8',
                                       'ServerAdmin' => 'you@example.com',
                                       'TypesConfig' => 'conf/mime.types',
                                       'DocumentRoot' => '/home/mschout/dev/perls/5.8.8/htdocs',
                                       'LoadModule' => []
                                     },
                 'cmodules_disabled' => {},
                 'preamble_hooks' => [
                                       'configure_libmodperl',
                                       sub { "DUMMY" }
                                     ],
                 'preamble' => [
                                 '<IfModule !mod_perl.c>
    LoadModule perl_module "/home/mschout/dev/perls/5.8.8/modules/mod_perl.so"
</IfModule>
',
                                 ''
                               ],
                 'vars' => {
                             'defines' => '',
                             'cgi_module_name' => 'mod_cgi',
                             'conf_dir' => '/home/mschout/dev/perls/5.8.8/conf',
                             't_conf_file' => '/home/mschout/dev/apache-authcookie/t/conf/httpd.conf',
                             't_dir' => '/home/mschout/dev/apache-authcookie/t',
                             'libmodperl' => '/home/mschout/dev/perls/5.8.8/modules/mod_perl.so',
                             'cgi_module' => 'mod_cgi.c',
                             'target' => 'httpd',
                             'thread_module' => 'worker.c',
                             'bindir' => '/home/mschout/dev/perls/5.8.8/bin',
                             'user' => 'mschout',
                             'access_module_name' => 'mod_access',
                             'auth_module_name' => 'mod_auth',
                             'top_dir' => '/home/mschout/dev/apache-authcookie',
                             'httpd_conf' => '/home/mschout/dev/perls/5.8.8/conf/httpd.conf',
                             'httpd' => '/home/mschout/dev/perls/5.8.8/bin/httpd',
                             'scheme' => 'http',
                             'ssl_module_name' => 'mod_ssl',
                             'port' => 8529,
                             'sbindir' => '/home/mschout/dev/perls/5.8.8/bin',
                             't_conf' => '/home/mschout/dev/apache-authcookie/t/conf',
                             'servername' => 'localhost',
                             'inherit_documentroot' => '/home/mschout/dev/perls/5.8.8/htdocs',
                             'proxy' => 'off',
                             'serveradmin' => 'you@example.com',
                             'remote_addr' => '127.0.0.1',
                             'perlpod' => '/home/mschout/dev/perls/5.8.8/lib/perl5/pod',
                             'sslcaorg' => 'asf',
                             'php_module_name' => 'sapi_apache2',
                             'maxclients_preset' => 0,
                             'php_module' => 'sapi_apache2.c',
                             'ssl_module' => 'mod_ssl.c',
                             'auth_module' => 'mod_auth.c',
                             'access_module' => 'mod_access.c',
                             't_logs' => '/home/mschout/dev/apache-authcookie/t/logs',
                             'minclients' => 1,
                             'maxclients' => 2,
                             'group' => 'mschout',
                             'maxclientsthreadedmpm' => 2,
                             'thread_module_name' => 'worker',
                             'documentroot' => '/home/mschout/dev/apache-authcookie/t/htdocs',
                             'serverroot' => '/home/mschout/dev/apache-authcookie/t',
                             'sslca' => '/home/mschout/dev/apache-authcookie/t/conf/ssl/ca',
                             'perl' => '/home/mschout/dev/perls/5.8.8/bin/perl',
                             'src_dir' => undef,
                             'proxyssl_url' => ''
                           },
                 'clean' => {
                              'files' => {
                                           '/home/mschout/dev/apache-authcookie/t/conf/apache_test_config.pm' => 1,
                                           '/home/mschout/dev/apache-authcookie/t/conf/modperl_startup.pl' => 1,
                                           '/home/mschout/dev/apache-authcookie/t/conf/extra.conf' => 1,
                                           '/home/mschout/dev/apache-authcookie/t/conf/httpd.conf' => 1,
                                           '/home/mschout/dev/apache-authcookie/t/logs/apache_runtime_status.sem' => 1,
                                           '/home/mschout/dev/apache-authcookie/t/conf/modperl_inc.pl' => 1,
                                           '/home/mschout/dev/apache-authcookie/t/htdocs/index.html' => 1
                                         },
                              'dirs' => {
                                          '/home/mschout/dev/apache-authcookie/t/logs' => 1
                                        }
                            },
                 'httpd_info' => {
                                   'BUILT' => 'Feb 15 2010 22:55:55',
                                   'MODULE_MAGIC_NUMBER_MINOR' => '9',
                                   'VERSION' => 'Apache/2.0.53',
                                   'MODULE_MAGIC_NUMBER' => '20020903:9',
                                   'MODULE_MAGIC_NUMBER_MAJOR' => '20020903'
                                 },
                 'modules' => {
                                'mod_include.c' => 1,
                                'mod_asis.c' => 1,
                                'mod_env.c' => 1,
                                'mod_negotiation.c' => 1,
                                'core.c' => 1,
                                'http_core.c' => 1,
                                'mod_access.c' => 1,
                                'mod_setenvif.c' => 1,
                                'mod_dir.c' => 1,
                                'prefork.c' => 1,
                                'mod_actions.c' => 1,
                                'mod_cgi.c' => 1,
                                'mod_so.c' => 1,
                                'mod_perl.c' => '/home/mschout/dev/perls/5.8.8/modules/mod_perl.so',
                                'mod_alias.c' => 1,
                                'mod_imap.c' => 1,
                                'mod_status.c' => 1,
                                'mod_autoindex.c' => 1,
                                'mod_auth.c' => 1,
                                'mod_log_config.c' => 1,
                                'mod_userdir.c' => 1,
                                'mod_mime.c' => 1
                              },
                 'httpd_defines' => {
                                      'SUEXEC_BIN' => '/home/mschout/dev/perls/5.8.8/bin/suexec',
                                      'APR_HAS_MMAP' => 1,
                                      'APR_HAS_OTHER_CHILD' => 1,
                                      'DEFAULT_PIDLOG' => 'logs/httpd.pid',
                                      'AP_TYPES_CONFIG_FILE' => 'conf/mime.types',
                                      'DEFAULT_SCOREBOARD' => 'logs/apache_runtime_status',
                                      'DEFAULT_LOCKFILE' => 'logs/accept.lock',
                                      'APR_USE_SYSVSEM_SERIALIZE' => 1,
                                      'APR_HAVE_IPV6 (IPv4-mapped addresses enabled)' => 1,
                                      'SINGLE_LISTEN_UNSERIALIZED_ACCEPT' => 1,
                                      'APACHE_MPM_DIR' => 'server/mpm/prefork',
                                      'DEFAULT_ERRORLOG' => 'logs/error_log',
                                      'APR_HAS_SENDFILE' => 1,
                                      'HTTPD_ROOT' => '/home/mschout/dev/perls/5.8.8',
                                      'AP_HAVE_RELIABLE_PIPED_LOGS' => 1,
                                      'SERVER_CONFIG_FILE' => 'conf/httpd.conf',
                                      'APR_USE_PTHREAD_SERIALIZE' => 1
                                    }
               }, 'Apache::TestConfig' );
}

1;
