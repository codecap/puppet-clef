#! /usr/bin/env ruby -S rspec

require 'spec_helper'

describe Puppet::Parser::Functions.function(:data_to_config) do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  describe 'when calling data_to_config from puppet with wrong arguments' do
    it "should not compile when no arguments are passed" do
      Puppet[:code] = '$x = data_to_config()'
      expect {
        scope.compiler.compile
       }.to raise_error(Puppet::ParseError, /wrong number of arguments/)
    end

    it "should not compile when the firtst argument is neither an array nor a hash" do
      Puppet[:code] = '$x = data_to_config("string")'
      expect {
        scope.compiler.compile
       }.to raise_error(Puppet::ParseError, /requires an array or a hash/)
    end

      it "should not compile when the second argument is not a hash of settings" do
      Puppet[:code] = '$x = data_to_config({}, "string")'
      expect {
        scope.compiler.compile
       }.to raise_error(Puppet::ParseError, /requires a hash of settings as second argument/)
    end
  end


  describe 'when calling data_to_config on the scope instance' do

    data = {
      'sssd' => {
        'config_file_version'  => 2,
        'reconnection_retries' => 3,
        'sbus_timeout'         => 30,
        'services'             => 'nss, pam, sudo, ssh',
        'domains'              => 'default',
      },
    }

    it 'should be able to convert a hash to a config' do
      config = scope.function_data_to_config([data])

      lines =  config.split("\n")

      expect(lines[0]).to   match(/^\[sssd\]$/)
      expect(lines[1]).to   match(/^    config_file_version += 2/)
      expect(lines[2]).to   match(/^    domains += "default"/)
      expect(lines[3]).to   match(/^    reconnection_retries += 3/)
      expect(lines[4]).to   match(/^    sbus_timeout += 30/)
      expect(lines[5]).to   match(/^    services += "nss, pam, sudo, ssh"/)
    end


    it 'should be able to convert an array to config' do
      data = [
        'str01',
        'str02',
        {'section' =>  {
            'key02' => 'value02',
            'key01' => 'value01',
            'key03' => [
              'value031',
              'value032',
              'value033',
            ],
            'key04' => 'value04',
        }},
        'str03',
        'str04',
        'str05',
      ]

      settings = {'quote_mark' => ''}

      config = scope.function_data_to_config([data, settings])
      lines =  config.split("\n")

      expect(lines[0]).to   match(/^str01/)
      expect(lines[1]).to   match(/^str02/)
      expect(lines[2]).to   match(/^\[section\]/)
      expect(lines[3]).to   match(/^    key01 += value01/)
      expect(lines[4]).to   match(/^    key02 += value02/)
      expect(lines[5]).to   match(/^    \[key03\]/)
      expect(lines[6]).to   match(/^        value031/)
      expect(lines[7]).to   match(/^        value032/)
      expect(lines[8]).to   match(/^        value033/)
      expect(lines[9]).to   match(/^    key04 += value04/)
      expect(lines[10]).to  match(/^str03/)
      expect(lines[11]).to  match(/^str04/)
      expect(lines[12]).to  match(/^str05/)
    end

    it 'should handle settings: preffix/suffix' do
      # prefix/suffix
      settings = {
        'prefix' => '<',
        'suffix'  => '>',
      }

      data = {
        'section1' => {
          'key11' => 'value11',
          'key12' => 'value12',
          'section2' => {
            'key11' => 'key11',
            'key12' => 'key12',
          }
        },
      }

      config = scope.function_data_to_config([data, settings])
      lines =  config.split("\n")

      expect(lines[0]).to   match(/^<section1>$/)
      expect(lines[1]).to   match(/^    key11 += \"value11\"$/)
      expect(lines[3]).to   match(/^    <section2>$/)
    end

    it 'should handle settings: indendation' do
      # Indendation
      settings = {
        'indent' => '',
      }
      data = {
        'section1' => {
          'key11' => 'value11',
          'key12' => 'value12',
          'section2' => {
            'key11' => 'key11',
            'key12' => 'key12',
          }
        },
      }

      config = scope.function_data_to_config([data, settings])
      lines  =  config.split("\n")

      (0..5).to_a.each do |i|
        expect(lines[i]).to   match(/^[^ ]/)
      end

      # opening/cloding mark
    end


    it 'should handle settings: indendation' do
      # Indendation
      settings = {
        'opening_mark' => ' {',
        'closing_mark' => '}',
      }
      data = {
        'section1' => {
          'key11' => 'value11',
          'key12' => 'value12',
          'section2' => {
            'key11' => 'key11',
            'key12' => 'key12',
          }
        },
      }

      config = scope.function_data_to_config([data, settings])
      lines  =  config.split("\n")

      expect(lines[0]).to   match(/^\[section1\] \{$/)
      expect(lines[1]).to   match(/^    key11                        = "value11"$/)
      expect(lines[2]).to   match(/^    key12                        = "value12"$/)
      expect(lines[3]).to   match(/^    \[section2\] \{$/)
      expect(lines[4]).to   match(/^        key11                    = "key11"$/)
      expect(lines[5]).to   match(/^        key12                    = "key12"$/)
      expect(lines[6]).to   match(/^    \}$/)
    end

    it 'should be able to handle custom settings for an element' do
      data = {
        'section1' => {
          'key11' => 'value11',
          'key12' => 'value12',
          'section2' => {
            'key21' => 'value21',
            'key22' => 'value22',
            '__CUSTOM_SETTINGS__' => {
              'opening_mark' => ' {',
              'closing_mark' => '}',
              'quote_mark'   => '',
              'prefix'       => '<',
              'suffix'       => '>',
              'separator'    => ' => ',
              'indent'       => '        ',
         }
          }
        },
      }

      config = scope.function_data_to_config([data])
      lines  =  config.split("\n")

      expect(lines[0]).to   match(/^\[section1\]$/)
      expect(lines[1]).to   match(/^    key11                        = "value11"$/)
      expect(lines[2]).to   match(/^    key12                        = "value12"$/)
      expect(lines[3]).to   match(/^        <section2> \{$/)
      expect(lines[4]).to   match(/^                key21            => value21$/)
      expect(lines[5]).to   match(/^                key22            => value22$/)
      expect(lines[6]).to   match(/^        \}$/)
    end

    it 'should handle custom fragments' do
      data = {
        'section1' => {
          'key11' => 'value11',
          'key12' => 'value12',
          'section2' => {
            '__CUSTOM_FRAGMENT__' => 'JUST A LINE',
          },
          'section3' => {
            '__CUSTOM_FRAGMENT__' => [
              'custom_line31',
              'custom_line32',
              'custom_line33',
            ]
          },
        },
      }

      config = scope.function_data_to_config([data])
      lines  =  config.split("\n")

      expect(lines[0]).to   match(/\[section1\]/)
      expect(lines[1]).to   match(/    key11                        = "value11"/)
      expect(lines[2]).to   match(/    key12                        = "value12"/)
      expect(lines[3]).to   match(/    \[section2\]/)
      expect(lines[4]).to   match(/        JUST A LINE/)
      expect(lines[5]).to   match(/    \[section3\]/)
      expect(lines[6]).to   match(/        custom_line31/)
      expect(lines[7]).to   match(/        custom_line32/)
      expect(lines[8]).to   match(/        custom_line33/)
    end


    it 'should be able to generate a flat file' do
      data = {
        '#AcceptEnvs' => [
          'AcceptEnv LC_IDENTIFICATION LC_ALL   LANGUAGE',
          'AcceptEnv XMODIFIERS',
        ],
        '#Settings' => {
          'PasswordAuthentication'          => 'no',
          'X11Forwarding'                   => 'yes',
          'UseDNS'                          => 'no',
        }
      }

      settings = {
        'prefix'         => '',
        'suffix'         => '',
        'separator'      => '',
        'opening_mark'   => '',
        'closing_mark'   => '',
        'quote_mark'     => '',
        'indent'         => '',
        'format_length'  => 32,
      }


      config = scope.function_data_to_config([data, settings])
      lines  = config.split("\n")



      expect(lines[0]).to     match(/^#AcceptEnvs$/)
      expect(lines[1]).to     match(/^AcceptEnv LC_IDENTIFICATION LC_ALL   LANGUAGE$/)
      expect(lines[2]).to     match(/^AcceptEnv XMODIFIERS$/)
      expect(lines[3]).to     match(/^#Settings$/)
      expect(lines[4]).to     match(/^PasswordAuthentication          no$/)
      expect(lines[5]).to     match(/^UseDNS                          no$/)
      expect(lines[6]).to     match(/^X11Forwarding                   yes$/)

    end

    it 'should be able to generate a tree file' do

      data = [{
        'sssd_config' => {
          'sssd' => {
            'config_file_version'  => 1,
            'reconnection_retries' => 5,
            'sbus_timeout'         => 30,
          },
          'nss' => {
            'reconnection_retries' => 5,
          },
          'pam' => {
            'reconnection_retries'  => 5,
          },
          'domain/default' => {
            'id_provider'           => 'ldap',
            'ldap_pwd_policy'       => 'none',
            'enumerate'             => 'True',
            'cache_credentials'     => 'True',
          },
        },
      }]

      settings = {
        'quote_mark'     => '',
        'indent'         => '  ',
      }

      config = scope.function_data_to_config([data, settings])
      lines  = config.split("\n")


      expect(lines[0]).to       match(/^\[sssd_config\]$/)
      expect(lines[1]).to       match(/^  \[domain\/default\]$/)
      expect(lines[2]).to       match(/^    cache_credentials            = True$/)
      expect(lines[3]).to       match(/^    enumerate                    = True$/)
      expect(lines[4]).to       match(/^    id_provider                  = ldap$/)
      expect(lines[5]).to       match(/^    ldap_pwd_policy              = none$/)
      expect(lines[6]).to       match(/^  \[nss\]$/)
      expect(lines[7]).to       match(/^    reconnection_retries         = 5$/)
      expect(lines[8]).to       match(/^  \[pam\]$/)
      expect(lines[9]).to       match(/^    reconnection_retries         = 5$/)
      expect(lines[10]).to      match(/^  \[sssd\]$/)
      expect(lines[11]).to      match(/^    config_file_version          = 1$/)
      expect(lines[12]).to      match(/^    reconnection_retries         = 5$/)
      expect(lines[13]).to      match(/^    sbus_timeout                 = 30$/)
    end
  end
end
