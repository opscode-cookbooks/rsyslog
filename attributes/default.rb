#
# Cookbook:: rsyslog
# Attributes:: default
#
# Copyright:: 2009-2019, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

default['rsyslog']['local_host_name']           = nil
default['rsyslog']['default_log_dir']           = '/var/log'
default['rsyslog']['log_dir']                   = '/srv/rsyslog'
default['rsyslog']['working_dir']               = '/var/spool/rsyslog'
default['rsyslog']['working_dir_mode']          = '0700'
default['rsyslog']['server']                    = false
default['rsyslog']['use_relp']                  = false
default['rsyslog']['relp_port']                 = 20_514
default['rsyslog']['protocol']                  = 'tcp'
default['rsyslog']['bind']                      = '*'
default['rsyslog']['port']                      = 514
default['rsyslog']['server_ip']                 = nil
default['rsyslog']['server_search']             = 'role:loghost'
default['rsyslog']['remote_logs']               = true
default['rsyslog']['per_host_dir']              = '%$YEAR%/%$MONTH%/%$DAY%/%HOSTNAME%'
default['rsyslog']['max_message_size']          = '2k'
default['rsyslog']['preserve_fqdn']             = 'off'
default['rsyslog']['high_precision_timestamps'] = false
default['rsyslog']['repeated_msg_reduction']    = 'on'
default['rsyslog']['logs_to_forward']           = '*.*'
default['rsyslog']['enable_imklog']             = true
default['rsyslog']['config_prefix']             = '/etc'
default['rsyslog']['default_file_template']     = nil
default['rsyslog']['default_remote_template']   = nil
default['rsyslog']['rate_limit_interval']       = nil
default['rsyslog']['rate_limit_burst']          = nil
default['rsyslog']['enable_tls']                = false
default['rsyslog']['tls_driver']                = if platform_family?('rhel') && platform_version.to_i == 7
                                                    'gtls'
                                                  else
                                                    'ossl'
                                                  end
default['rsyslog']['action_queue_max_disk_space'] = '1G'
default['rsyslog']['tls_ca_file']               = nil
default['rsyslog']['tls_certificate_file']      = nil
default['rsyslog']['tls_key_file']              = nil
default['rsyslog']['tls_auth_mode']             = 'anon'
default['rsyslog']['tls_permitted_peer']        = nil
default['rsyslog']['use_local_ipv4']            = false
default['rsyslog']['allow_non_local']           = false
default['rsyslog']['custom_remote']             = []
default['rsyslog']['additional_directives']     = {}
default['rsyslog']['templates']                 = %w()
default['rsyslog']['default_conf_file']         = true
default['rsyslog']['server_per_host_template']  = '35-server-per-host.conf.erb'
default['rsyslog']['server_per_host_cookbook']  = 'rsyslog'

# The most likely platform-specific attributes
default['rsyslog']['package_name']              = 'rsyslog'
default['rsyslog']['service_name']              = 'rsyslog'
default['rsyslog']['user']                      = 'root'
default['rsyslog']['group']                     = 'adm'
default['rsyslog']['priv_seperation']           = false
default['rsyslog']['priv_user']                 = nil
default['rsyslog']['priv_group']                = nil
default['rsyslog']['modules']                   = %w(imuxsock imklog)
default['rsyslog']['file_create_mode']          = '0640'
default['rsyslog']['dir_create_mode']           = '0755'
default['rsyslog']['umask']                     = '0022'
default['rsyslog']['dir_owner']                 = 'root'
default['rsyslog']['dir_group']                 = 'adm'
default['rsyslog']['config_files']['owner']     = 'root'
default['rsyslog']['config_files']['group']     = 'root'
default['rsyslog']['config_files']['mode']      = '0644'
default['rsyslog']['config_dir']['mode']        = '0755'

# platform specific attributes
case node['platform']
when 'ubuntu'
  default['rsyslog']['user'] = 'syslog'
  default['rsyslog']['dir_owner'] = 'syslog'
  default['rsyslog']['group'] = 'adm'
  default['rsyslog']['priv_seperation'] = true
  default['rsyslog']['priv_group'] = 'syslog'
when 'smartos'
  default['rsyslog']['config_prefix'] = '/opt/local/etc'
  # NOTE: remove imudp and imtcp since there are no default listeners on SmartOS
  default['rsyslog']['modules'] = %w(immark imsolaris)
  default['rsyslog']['group'] = 'root'
when 'omnios'
  default['rsyslog']['service_name'] = 'system/rsyslogd'
  default['rsyslog']['modules'] = %w(immark imsolaris imtcp imudp)
  default['rsyslog']['group'] = 'root'
when 'freebsd'
  default['rsyslog']['group'] = 'wheel'
  default['rsyslog']['dir_group'] = 'wheel'
  default['rsyslog']['service_name'] = 'rsyslogd'
  default['rsyslog']['config_prefix'] = '/usr/local/etc'
end

# platform family specific attributes
case node['platform_family']
when 'smartos'
  # These defaults match what is shipped in the pkgsrc rsyslog package
  default['rsyslog']['default_facility_logs'] = {
    '*.alert;kern.err;daemon.err' => ':omusrmsg:operator',
    '*.alert' => ':omusrmsg:root',
    '*.emerg' => ':omusrmsg:*',
    '*.err;kern.notice;auth.notice' => '/dev/sysmsg',
    '*.err;kern.debug;daemon.notice;mail.crit' => '/var/adm/messages',
    'mail.debug' => "#{node['rsyslog']['default_log_dir']}/syslog",
    'mail.info' => "#{node['rsyslog']['default_log_dir']}/maillog",
    'auth.info' => "#{node['rsyslog']['default_log_dir']}/authlog",
  }
when 'suse'
  default['rsyslog']['service_name'] = 'syslog'
  default['rsyslog']['group'] = 'root'
  default['rsyslog']['dir_group'] = 'trusted'
  default['rsyslog']['default_facility_logs'] = {
    '*.emerg' => ':omusrmsg:*',
    'mail.*' => "-#{node['rsyslog']['default_log_dir']}/mail.log",
    'mail.info' => "-#{node['rsyslog']['default_log_dir']}/mail.info",
    'mail.warning' => "-#{node['rsyslog']['default_log_dir']}/mail.warn",
    'mail.err' => "#{node['rsyslog']['default_log_dir']}/mail.err",
    'news.crit' => "#{node['rsyslog']['default_log_dir']}/news/news.crit",
    'news.err' => "#{node['rsyslog']['default_log_dir']}/news/news.err",
    'news.notice' => "-#{node['rsyslog']['default_log_dir']}/news/news.notice",
    '*.=warning;*.=err' => "-#{node['rsyslog']['default_log_dir']}/warn",
    '*.crit' => "#{node['rsyslog']['default_log_dir']}/warn",
    '*.*;mail.none;news.none' => "#{node['rsyslog']['default_log_dir']}/messages",
    'local0.*;local1.*' => "-#{node['rsyslog']['default_log_dir']}/localmessages",
    'local2.*;local3.*' => "-#{node['rsyslog']['default_log_dir']}/localmessages",
    'local4.*;local5.*' => "-#{node['rsyslog']['default_log_dir']}/localmessages",
    'local6.*;local7.*' => "-#{node['rsyslog']['default_log_dir']}/localmessages",
  }
when 'rhel', 'fedora', 'amazon'
  default['rsyslog']['working_dir'] = '/var/lib/rsyslog'
  # format { facility => destination }
  default['rsyslog']['default_facility_logs'] = {
    '*.info;mail.none;authpriv.none;cron.none' => "#{node['rsyslog']['default_log_dir']}/messages",
    'authpriv.*' => "#{node['rsyslog']['default_log_dir']}/secure",
    'mail.*' => "-#{node['rsyslog']['default_log_dir']}/maillog",
    'cron.*' => "#{node['rsyslog']['default_log_dir']}/cron",
    '*.emerg' => ':omusrmsg:*',
    'uucp,news.crit' => "#{node['rsyslog']['default_log_dir']}/spooler",
    'local7.*' => "#{node['rsyslog']['default_log_dir']}/boot.log",
  }
  default['rsyslog']['modules'] = %w(imuxsock imjournal)
  default['rsyslog']['additional_directives'] = { 'OmitLocalLogging' => 'on', 'IMJournalStateFile' => 'imjournal.state' }
else
  # format { facility => destination }
  default['rsyslog']['default_facility_logs'] = {
    'auth,authpriv.*' => "#{node['rsyslog']['default_log_dir']}/auth.log",
    '*.*;auth,authpriv.none' => "-#{node['rsyslog']['default_log_dir']}/syslog",
    'daemon.*' => "-#{node['rsyslog']['default_log_dir']}/daemon.log",
    'kern.*' => "-#{node['rsyslog']['default_log_dir']}/kern.log",
    'mail.*' => "-#{node['rsyslog']['default_log_dir']}/mail.log",
    'user.*' => "-#{node['rsyslog']['default_log_dir']}/user.log",
    'mail.info' => "-#{node['rsyslog']['default_log_dir']}/mail.info",
    'mail.warn' => "-#{node['rsyslog']['default_log_dir']}/mail.warn",
    'mail.err' => "#{node['rsyslog']['default_log_dir']}/mail.err",
    'news.crit' => "#{node['rsyslog']['default_log_dir']}/news/news.crit",
    'news.err' => "#{node['rsyslog']['default_log_dir']}/news/news.err",
    'news.notice' => "-#{node['rsyslog']['default_log_dir']}/news/news.notice",
    '*.=debug;auth,authpriv.none;news.none;mail.none' => "-#{node['rsyslog']['default_log_dir']}/debug",
    '*.=info;*.=notice;*.=warn;auth,authpriv.none;cron,daemon.none;mail,news.none' => "-#{node['rsyslog']['default_log_dir']}/messages",
    '*.emerg' => ':omusrmsg:*',
  }
end
