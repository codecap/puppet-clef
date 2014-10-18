require 'yaml'

@default_settings = {
    'prefix'         => '[',
    'suffix'         => ']',
    'separator'      => ' = ',
    'opening_mark'   => '',
    'closing_mark'   => '',
    'quote_mark'     => '"',
    'indent'         => '    ',
    'format_length'  => 24,
}


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
]

def printElement data, level = nil, settings = nil
    if data.is_a?(Hash)
        return printHash(data,     level, settings)
    elsif data.is_a?(Array)
        return printHash(data,     level, settings)
    else
        return printVariable(data, level, settings)
    end
end

def printVariable variable, level = nil, settings = nil

    use_quotes = !(variable.is_a?Fixnum or variable.is_a?FalseClass or variable.is_a?TrueClass)

    sprintf(  "%s%s%s",
        use_quotes ? settings['quote_mark'] : '',
        variable.to_s,
        use_quotes ? settings['quote_mark'] : '',
    )
end

def printArray data, level = nil, settings = nil

    level = 0 if level.nil?

    output = []
    data.each do |e|
        output << printElement(e, level, settings)
    end
    output.join("\n")
end

def printHash data, level = nil, settings = nil

    output   = []

    name    = data.keys[0]
    content = data.dup

    custom_settings = content[name].delete('__CUSTOM_SETTINGS__')

    settings        = @default_settings.dup if settings == nil
    settings        = settings.merge(custom_settings.nil? ? {} : custom_settings)


    #
    # Print section name
    #
    if (settings['prefix'] + name + settings['suffix'] + settings['opening_mark']) != ''
        output << sprintf("%s%s%s%s%s",
            settings['indent'] * level,
            settings['prefix'],
            name,
            settings['suffix'],
            settings['opening_mark']
        )
    end

    #
    # Print content according to the type
    #
    content.delete('__CUSTOM_FRAGMENT__')

    content.keys().sort().each do |k|
        v = content[k]

        custom_fragment = v.delete('__CUSTOM_FRAGMENT__')

        if v.is_a?(Hash)
            v.keys.sort.each do |kk|
                if v[kk].is_a?Hash
                    output <<  printHash( {kk => v[kk]}, level + 1, settings)
                elsif v[kk].is_a?Array
                    output << printArray(v[kk], level + 1, settings)
                else
                    str = printVariable(v[kk], level + 1, settings)

                    l = settings['format_length'] - (settings['indent'] * (level+1)).length

                    output << sprintf("%s%-#{l}s%s%s",
                        settings['indent'] * (level+1),
                        kk,
                        settings['separator'],
                        str
                    )
                end
            end
        end

        #
        # Print custom fragent
        #
        if ! custom_fragment.nil?
            custom_str = ''
            if custom_fragment.is_a?(Array)
                custom_str = custom_fragment.map { |e|  settings['indent']*(level+1) + e.to_s}.join("\n")
            else
                custom_str = custom_fragment.to_s
            end
            output << custom_str
        end
    end

    #
    # Print the section closing mark
    #
    if settings['closing_mark'] != ''
        output << sprintf("%s%s",
            settings['indent']*level,
            settings['closing_mark']
        )
    end
    output.join("\n")
end

Puppet::Parser::Functions.newfunction(:data_to_config, :type => :rvalue, :doc =>
  "Function that converts an array of hashes to a configuration string") do |args|
  if args.length < 1 or args.length > 2
    raise Puppet::Error, "#hash_to_xml accepts only one (1) or two (2) arguments, you passed #{args.length}"
  end

  if args[0].is_a?Hash or arg.is_a?Array
    raise Puppet::Error, "#data_to_config requires an array or a hash as the first argument, you passed a #{args[0].class}"
  end

  if !args[1].nil? and !arg.is_a?Hash
    raise Puppet::Error, "#data_to_config requires an array or a settings hash as second argument"
  end


  if args[0].is_a?Hash
    printHash(args[0],  nil, args[1])
  elsif args[0].is_a?Array
    printArray(args[0], nil, args[1])
  end
end
