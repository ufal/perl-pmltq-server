{
  # see https://metacpan.org/pod/DBIx::Class::Storage::DBI#connect_info
  database => {
    dsn => 'dbi:SQLite:dbname=share/pmltq-server.db',
    user => '',
    password => '',
    sqlite_unicode => 1
  },

  # Enable Shibboleth login and than protect url /v1/auth/shibboleth by Shibboleth
  #
  # Without protecting url with Shibboleth opens your app to attackers because anyone
  # could fake Shibboleth headers.
  shibboleth => 0,
  tree_print_service => 'http://localhost:8070/svg',
  nodes_to_query_service => 'http://localhost:8070/pmltq',
  data_dir => '/opt/pmltq/data',
  tmp_dir => '/tmp/',

  mail_templates =>
    {
      registration =>
        {
          subject => 'registration',
          text => 'Dear %%NAME%%,

your account has been created. Please remember the following login data:
      username: "%%USERNAME%%"
      password: "%%PLAIN_PASSWORD%%"
You can follow %%HOME%% to login.

Sincerely,
PMLTQ Team
'
        }
    }
};
