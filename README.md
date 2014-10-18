## Clef - nice tool to generate configuration from data structures


Clef gives you a possibility to convert an array or a hash to a configuration
string, which can be then pass to a file puppet resource as its content.

At the momment only one function is implemented:

data_to_config(data, settings = nil)

It accepts the folowing arguments:

** data:** can be an array or a hash
Every hash can contain the following special keys:
  __CUSTOM_FRAGMENT__ - custom fragment (string or an array of strings)
  __CUSTOM_SETTINGS__ - used to set custom settings for the current section
**settings:** is a set of settings to apply generating configuration

Default settings
  prefix         => '['
  suffix         => ']'
  separator      => ' = '
  opening_mark   => ''
  closing_mark   => ''
  quote_mark     => '"'
  indent         => '    '
  format_length  => 24


### Converting data to a configuration

h = [
    {
        'logging' => {
            'default'      => 'FILE:/var/log/krb5libs.log',
            'kdc'          => 'FILE:/var/log/krb5kdc.log',
            'admin_server' => 'FILE:/var/log/kadmind.log',
            'realms' => {
                '__CUSTOM_FRAGMENT__' => [
                    'EXAMPLE.COM = {',
                    '    kdc          = kerberos.example.com',
                    '    admin_server = kerberos.example.com',
                    '}',
                ]
            },
     }},
    {
        'libdefaults' => {
            'default_realm'    => 'EXAMPLE.COM',
            'dns_lookup_realm' => false,
            'dns_lookup_kdc'   => false,
            'ticket_lifetime'  => '24h',
            'renew_lifetime'   => '7d',
            'forwardable'      => true,
            'subsection'       => {
                'set_key01' => 'set_val01',
                'set_key02' => 'set_val02',
                'set_key03' => 'set_val03',
            },
            '__CUSTOM_SETTINGS__' => {
                'prefix'         => '<',
                'suffix'         => '>',
                'separator'      => ' => ',
                'opening_mark'   => ' {',
                'closing_mark'   => '}',
                'quote_mark'     => "'",
            },

    }},
    {'realms' => {
      '__CUSTOM_FRAGMENT__' => [
          'EXAMPLE.COM = {',
          '    kdc = kerberos.example.com',
          '    admin_server = kerberos.example.com',
          '}',
      ]
    }},
    {'domain_realm' => {
        '.example.com' => 'EXAMPLE.COM',
        'example.com'  => 'EXAMPLE.COM',
    }},
    {'' => {
        '__CUSTOM_SETTINGS__' => {
            'prefix'         => '',
            'suffix'         => '',
            'indent' => '',
        },
        'key01' => 'val01',
        'key02' => 'val02',
        'key03' => 3,
    }},

    file { '/etc/service.conf':
      ensure  => file,
      content => data_to_config($hash)
    }

### The resulting configuration file
```
[logging]
    admin_server         = "FILE:/var/log/kadmind.log"
    default              = "FILE:/var/log/krb5libs.log"
    kdc                  = "FILE:/var/log/krb5kdc.log"
    [realms]
        EXAMPLE.COM = {
            kdc          = kerberos.example.com
            admin_server = kerberos.example.com
        }
<libdefaults> {
    default_realm        => 'EXAMPLE.COM'
    dns_lookup_kdc       => false
    dns_lookup_realm     => false
    forwardable          => true
    renew_lifetime       => '7d'
    <subsection> {
        set_key01        => 'set_val01'
        set_key02        => 'set_val02'
        set_key03        => 'set_val03'
    }
    ticket_lifetime      => '24h'
}
[realms]
    EXAMPLE.COM = {
        kdc = kerberos.example.com
        admin_server = kerberos.example.com
    }
[domain_realm]
    .example.com         = "EXAMPLE.COM"
    example.com          = "EXAMPLE.COM"
key01                    = "val01"
key02                    = "val02"
key03                    = 3
```
