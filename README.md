## Clef - nice tool to generate configuration from data structures


Clef gives you a possibility to convert an array or a hash to a configuration
string, which can be then passed to a file puppet resource as its content.

At the momment only one function is implemented:

```puppet
data_to_config(data, settings = nil)
```

It accepts the folowing arguments:

**data:** can be an array or a hash
Every hash can contain the following special keys:
  * **__CUSTOM_FRAGMENT__** - custom fragment (string or an array of strings)
  * **__CUSTOM_SETTINGS__** - used to set custom settings for the current section

**settings:** is a set of settings to apply generating configuration
```
Default settings
  prefix         => '['
  suffix         => ']'
  separator      => ' = '
  opening_mark   => ''
  closing_mark   => ''
  quote_mark     => '"'
  indent         => '    '
  format_length  => 24
```

### Converting data to a configuration


*sssd Configuration*
```puppet
$data = {
    'sssd' => {
      'config_file_version'  => 2,
      'reconnection_retries' => 3,
      'sbus_timeout'         => 30,
      'services'             => 'nss, pam, sudo, ssh',
      'domains'              => 'default',
    },
    'nss' => {
      'filter_groups'        => 'root',
      'filter_users'         => 'adm,amavis,apache',
      'reconnection_retries' => 3,
    },
    'pam' => {
      'reconnection_retries'  => 3,
    },
    'domain/default' => {
      'description'           => 'Plus.line LDAP-server',
      'id_provider'           => 'ldap',
      'auth_provider'         => 'ldap',
      'chpass_provider'       => 'ldap',
      'sudo_provider'         => 'ldap',
      'enumerate'             => 'True',
      'cache_credentials'     => 'True',
    },
  },
}

$settings = {
  quote_mark => '',
  indent     => '  ',
}

```
*Resulting sssd configuration file*
```
[domain/default]
  auth_provider                  = ldap
  cache_credentials              = True
  chpass_provider                = ldap
  description                    = Plus.line LDAP-server
  enumerate                      = True
  id_provider                    = ldap
  sudo_provider                  = ldap
[nss]
  filter_groups                  = root
  filter_users                   = adm,amavis,apache
  reconnection_retries           = 3
[pam]
  reconnection_retries           = 3
[sssd]
  config_file_version            = 2
  domains                        = default
  reconnection_retries           = 3
  sbus_timeout                   = 30
  services                       = nss, pam, sudo, ssh
```

*sshd Configuration*
```puppet
$data = {
  '#Settings'=> {
    'Protocol'                        => '2',
    'SyslogFacility'                  => 'AUTHPRIV',
    'LogLevel'                        => 'VERBOSE',
    'PermitRootLogin'                 => 'without-password',
    'RevokedKeys'                     => '/etc/ssh/revoked_keys',
    'PasswordAuthentication'          => 'yes',
    'ChallengeResponseAuthentication' => 'no',
    'UsePAM'                          => 'yes',
    'X11Forwarding'                   => 'yes',
    'UseDNS'                          => 'no',
    'Banner'                          => '/etc/issue.net',
    'Subsystem'                       => 'sftp /usr/libexec/openssh/sftp-server',
  },
  '#AcceptEnvs' => [
    'AcceptEnv LANG              LC_CTYPE LC_NUMERIC LC_TIME      LC_COLLATE      LC_MONETARY LC_MESSAGES',
    'AcceptEnv LC_PAPER          LC_NAME  LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT',
    'AcceptEnv LC_IDENTIFICATION LC_ALL   LANGUAGE',
    'AcceptEnv XMODIFIERS',
  ],
}

$settings = {
  prefix         => '',
  suffix         => '',
  separator      => '',
  opening_mark   => '',
  closing_mark   => '',
  quote_mark     => '',
  indent         => '',
  format_length  => 32,
}
```

*Resulting sshd configuration file*
```
#AcceptEnvs
AcceptEnv LANG              LC_CTYPE LC_NUMERIC LC_TIME      LC_COLLATE      LC_MONETARY LC_MESSAGES
AcceptEnv LC_PAPER          LC_NAME  LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT
AcceptEnv LC_IDENTIFICATION LC_ALL   LANGUAGE
AcceptEnv XMODIFIERS
#Settings
Banner                          /etc/issue.net
ChallengeResponseAuthentication no
LogLevel                        VERBOSE
PasswordAuthentication          yes
PermitRootLogin                 without-password
Protocol                        2
RevokedKeys                     /etc/ssh/revoked_keys
Subsystem                       sftp /usr/libexec/openssh/sftp-server
SyslogFacility                  AUTHPRIV
UseDNS                          no
UsePAM                          yes
X11Forwarding                   yes
```
