require 'yaml'


def getDefaultSettings
    {
        'prefix'         => '[',
        'suffix'         => ']',
        'separator'      => ' = ',
        'opening_mark'   => '',
        'closing_mark'   => '',
        'quote_mark'     => '"',
        'indent'         => '    ',
        'format_length'  => 32,
    }
end

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
        use_quotes ? settings['quote_mark'] : ''
    )
end

def printArray data, level = nil, settings = nil

    level     = 0                      if level.nil?
    settings  = getDefaultSettings.dup if settings.nil?

    output = []
    indent = settings['indent'] * level
    data.each do |e|
        e_str = printElement(e, level, settings)
        output << "#{indent}#{e_str}"
    end
    output.join("\n")
end

def printHash data, level = nil, settings = nil

    level = 0 if level.nil?
    output   = []

    name    = data.keys[0]
    content = data.dup

    custom_settings = content[name].delete('__CUSTOM_SETTINGS__')

    settings        = getDefaultSettings.dup if settings.nil?
    settings        = settings.merge(custom_settings.nil? ? {} : custom_settings)


    #
    # Print content according tomcat the type
    #
    content.delete('__CUSTOM_FRAGMENT__')

    content.keys().sort().each do |k|
        v = content[k]


        name = k
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

        custom_fragment = v.delete('__CUSTOM_FRAGMENT__')

        if v.is_a?(Hash)
            v.keys.sort.each do |kk|
                if v[kk].is_a?Hash
                    output <<  printHash( {kk => v[kk]}, level + 1, settings)
                elsif v[kk].is_a?Array
                    #
                    # Print section name
                    #
                    if (settings['prefix'] + kk + settings['suffix'] + settings['opening_mark']) != ''
                        output << sprintf("%s%s%s%s%s",
                            settings['indent'] * (level+1),
                            settings['prefix'],
                            kk,
                            settings['suffix'],
                            settings['opening_mark']
                        )
                    end
                    output << printArray(v[kk], level + 2, settings)
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
        elsif v.is_a?Array
            output << printArray(v, level, settings)
        end

        #
        # Print custom fragent
        #
        if ! custom_fragment.nil?
            custom_str = ''
            if custom_fragment.is_a?(Array)
                custom_str = custom_fragment.map { |e|  settings['indent']*(level+1) + e.to_s}.join("\n")
            else
                custom_str = settings['indent']*(level+1) + custom_fragment.to_s
            end
            output << custom_str
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
    end

    output.join("\n")
end

Puppet::Parser::Functions.newfunction(:data_to_config, :type => :rvalue, :doc =>
    "Function that converts an data (array or hashe) to a configuration string") do |args|
    if args.length < 1 or args.length > 2
        raise Puppet::ParseError, ("data_to_config(): wrong number of arguments (#{args.length}; must be exactly 1 or 2)")
    end

    if ! args[0].is_a?Hash and ! args[0].is_a?Array
        raise Puppet::ParseError, ("data_to_config():requires an array or a hash as the first argument, you passed a #{args[0].class}")
    end

    if !args[1].nil? and !args[1].is_a?Hash
        raise Puppet::ParseError, ("data_to_config(): requires a hash of settings as second argument")
    end

    data     = args[0]
    settings = args[1]

    if settings and settings.has_key?'format_length'
        settings['format_length'] = settings['format_length'].to_i
    end

    settings = getDefaultSettings.merge(settings ? settings : {})

    if data.is_a?Hash
        printHash(data,  nil, settings) + "\n"
    elsif data.is_a?Array
        printArray(data, nil, settings) + "\n"
    end
end
