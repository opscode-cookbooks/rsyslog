require 'spec_helper'

describe 'rsyslog::default' do
  let(:chef_run) do
    ChefSpec::ServerRunner.new(platform: 'ubuntu', version: '16.04').converge(described_recipe)
  end

  let(:service_resource) { 'service[rsyslog]' }

  it 'installs the rsyslog part' do
    expect(chef_run).to install_package('rsyslog')
  end

  context "when node['rsyslog']['relp'] is true" do
    let(:chef_run) do
      ChefSpec::ServerRunner.new(platform: 'ubuntu', version: '16.04') do |node|
        node.normal['rsyslog']['use_relp'] = true
      end.converge(described_recipe)
    end

    it 'installs the rsyslog-relp package' do
      expect(chef_run).to install_package('rsyslog-relp')
    end
  end

  context "when node['rsyslog']['enable_tls'] is true" do
    context "when node['rsyslog']['tls_ca_file'] is not set" do
      let(:chef_run) do
        ChefSpec::ServerRunner.new(platform: 'ubuntu', version: '16.04') do |node|
          node.normal['rsyslog']['enable_tls'] = true
        end.converge(described_recipe)
      end

      it 'does not install the rsyslog-gnutls package' do
        expect(chef_run).not_to install_package('rsyslog-gnutls')
      end
    end

    context "when node['rsyslog']['tls_ca_file'] is set" do
      let(:chef_run) do
        ChefSpec::ServerRunner.new(platform: 'ubuntu', version: '16.04') do |node|
          node.normal['rsyslog']['enable_tls'] = true
          node.normal['rsyslog']['tls_ca_file'] = '/etc/path/to/ssl-ca.crt'
        end.converge(described_recipe)
      end

      it 'installs the rsyslog-gnutls package' do
        expect(chef_run).to install_package('rsyslog-gnutls')
      end

      context "when protocol is not 'tcp'" do
        let(:chef_run) do
          ChefSpec::ServerRunner.new(platform: 'ubuntu', version: '16.04') do |node|
            node.normal['rsyslog']['enable_tls'] = true
            node.normal['rsyslog']['tls_ca_file'] = '/etc/path/to/ssl-ca.crt'
            node.normal['rsyslog']['protocol'] = 'udp'
          end.converge(described_recipe)
        end

        it 'exits fatally' do
          expect do
            chef_run
          end.to raise_error
        end
      end
    end
  end

  context '/etc/rsyslog.d directory' do
    let(:directory) { chef_run.directory('/etc/rsyslog.d') }

    it 'creates the directory' do
      expect(chef_run).to create_directory(directory.path)
    end

    it 'is owned by root:root' do
      expect(directory.owner).to eq('root')
      expect(directory.group).to eq('root')
    end

    it 'has 0755 permissions' do
      expect(directory.mode).to eq('0755')
    end

    context 'on SmartOS' do
      let(:chef_run) do
        ChefSpec::ServerRunner.new(platform: 'smartos', version: '5.11').converge(described_recipe)
      end

      let(:directory) { chef_run.directory('/opt/local/etc/rsyslog.d') }

      it 'creates the directory' do
        expect(chef_run).to create_directory(directory.path)
      end

      it 'is owned by root:root' do
        expect(directory.owner).to eq('root')
        expect(directory.group).to eq('root')
      end

      it 'has 0755 permissions' do
        expect(directory.mode).to eq('0755')
      end
    end
  end

  context '/var/spool/rsyslog directory' do
    let(:directory) { chef_run.directory('/var/spool/rsyslog') }

    it 'creates the directory' do
      expect(chef_run).to create_directory('/var/spool/rsyslog')
    end

    it 'is owned by root:root' do
      expect(directory.owner).to eq('syslog')
      expect(directory.group).to eq('adm')
    end

    it 'has 0700 permissions' do
      expect(directory.mode).to eq('0700')
    end
  end

  context '/etc/rsyslog.conf template' do
    let(:template) { chef_run.template('/etc/rsyslog.conf') }
    let(:modules) { %w(imuxsock imklog) }

    it 'creates the template' do
      expect(chef_run).to render_file(template.path).with_content('Config generated by Chef - manual edits will be overwritten')
    end

    it 'is owned by root:root' do
      expect(template.owner).to eq('root')
      expect(template.group).to eq('root')
    end

    it 'has 0644 permissions' do
      expect(template.mode).to eq('0644')
    end

    it 'notifies restarting the service' do
      expect(template).to notify(service_resource).to(:restart)
    end

    it 'includes the right modules' do
      modules.each do |mod|
        expect(chef_run).to render_file(template.path).with_content(/^\$ModLoad #{mod}/)
      end
    end

    context 'on SmartOS' do
      let(:chef_run) do
        ChefSpec::ServerRunner.new(platform: 'smartos', version: '5.11').converge(described_recipe)
      end

      let(:template) { chef_run.template('/opt/local/etc/rsyslog.conf') }
      let(:modules) { %w(immark imsolaris imtcp imudp) }

      it 'creates the template' do
        expect(chef_run).to render_file(template.path).with_content('Config generated by Chef - manual edits will be overwritten')
      end

      it 'is owned by root:root' do
        expect(template.owner).to eq('root')
        expect(template.group).to eq('root')
      end

      it 'has 0644 permissions' do
        expect(template.mode).to eq('0644')
      end

      it 'notifies restarting the service' do
        expect(template).to notify(service_resource).to(:restart)
      end

      it 'includes the right modules' do
        modules.each do |mod|
          expect(chef_run).to render_file(template.path).with_content(/^\$ModLoad #{mod}/)
        end
      end
    end
  end

  context '/etc/rsyslog.d/50-default.conf template' do
    let(:template) { chef_run.template('/etc/rsyslog.d/50-default.conf') }

    it 'creates the template' do
      expect(chef_run).to render_file(template.path).with_content('*.emerg    :omusrmsg:*')
    end

    it 'is owned by root:root' do
      expect(template.owner).to eq('root')
      expect(template.group).to eq('root')
    end

    it 'has 0644 permissions' do
      expect(template.mode).to eq('0644')
    end

    it 'notifies restarting the service' do
      expect(template).to notify(service_resource).to(:restart)
    end

    context 'on SmartOS' do
      let(:chef_run) do
        ChefSpec::ServerRunner.new(platform: 'smartos', version: '5.11').converge(described_recipe)
      end

      let(:template) { chef_run.template('/opt/local/etc/rsyslog.d/50-default.conf') }

      it 'creates the template' do
        expect(chef_run).to render_file(template.path).with_content('Default rules for rsyslog.')
      end

      it 'is owned by root:root' do
        expect(template.owner).to eq('root')
        expect(template.group).to eq('root')
      end

      it 'has 0644 permissions' do
        expect(template.mode).to eq('0644')
      end

      it 'notifies restarting the service' do
        expect(template).to notify(service_resource).to(:restart)
      end

      it 'uses the SmartOS-specific template' do
        expect(chef_run).to render_file(template.path).with_content(%r{/var/adm/messages$})
      end
    end
  end

  context 'COOK-3608 maillog regression test' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new(platform: 'centos', version: '6.9').converge(described_recipe)
    end

    it 'outputs mail.* to /var/log/maillog' do
      expect(chef_run).to render_file('/etc/rsyslog.d/50-default.conf').with_content('mail.*    -/var/log/maillog')
    end
  end

  context 'syslog service on rhel 5' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new(platform: 'centos', version: '5.11').converge(described_recipe)
    end

    it 'stops and starts the syslog service on RHEL' do
      expect(chef_run).to stop_service('syslog')
      expect(chef_run).to disable_service('syslog')
    end
  end

  context 'system-log service' do
    { 'omnios' => '151018', 'smartos' => '5.11' }.each do |p, pv|
      let(:chef_run) do
        ChefSpec::ServerRunner.new(platform: p, version: pv).converge(described_recipe)
      end

      it "stops the system-log service on #{p}" do
        expect(chef_run).to disable_service('system-log')
      end
    end
  end

  context 'on OmniOS' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new(platform: 'omnios', version: '151018').converge(described_recipe)
    end

    let(:template) { chef_run.template('/var/svc/manifest/system/rsyslogd.xml') }
    let(:execute) { chef_run.execute('import rsyslog manifest') }

    it 'creates the custom SMF manifest' do
      expect(chef_run).to render_file(template.path)
    end

    it 'notifies svccfg to import the manifest' do
      expect(template).to notify('execute[import rsyslog manifest]').to(:run)
    end

    it 'notifies rsyslog to restart when importing the manifest' do
      expect(execute).to notify('service[system/rsyslogd]').to(:restart)
    end
  end

  context 'rsyslog service' do
    it 'starts and enables the service' do
      expect(chef_run).to start_service('rsyslog')
    end
  end

  context "when node['rsyslog']['use_imfile'] is true" do
    context 'when on centos 6' do
      let(:chef_run) do
        ChefSpec::ServerRunner.new(platform: 'centos', version: '6') do |node|
          node.normal['rsyslog']['use_imfile'] = true
          node.normal['rsyslog']['imfile']['PollingInterval'] = 10
        end.converge(described_recipe)
      end
      let(:template) { chef_run.template('/etc/rsyslog.d/35-imfile.conf') }

      it "node['rsyslog']['config_style'] will be 'legacy' by default" do
        expect(chef_run.node['rsyslog']['config_style']).to eq('legacy')
      end
      context '/etc/rsyslog.d/35-imfile.conf file' do
        it 'will be create with legacy style syntax' do
          expect(chef_run).to render_file(template.path).with_content('$ModLoad imfile')
        end
        it 'will NOT include module parameter PollingInterval' do
          expect(chef_run).not_to render_file(template.path).with_content('PollingInterval')
        end
        it 'is owned by root:root' do
          expect(template.owner).to eq('root')
          expect(template.group).to eq('root')
        end

        it 'has 0644 permissions' do
          expect(template.mode).to eq('0644')
        end

        it 'notifies restarting the service' do
          expect(template).to notify(service_resource).to(:restart)
        end
      end
    end
    context 'when on ubuntu 16.04 ' do
      let(:chef_run) do
        ChefSpec::ServerRunner.new(platform: 'ubuntu', version: '16.04') do |node|
          node.normal['rsyslog']['use_imfile'] = true
          node.normal['rsyslog']['imfile']['PollingInterval'] = 10
        end.converge(described_recipe)
      end
      let(:template) { chef_run.template('/etc/rsyslog.d/35-imfile.conf') }

      it "node['rsyslog']['config_style'] will be nil by default" do
        expect(chef_run.node['rsyslog']['config_style']).to eq(nil)
      end

      context '/etc/rsyslog.d/35-imfile.conf file' do
        it 'will be created with Rainer style syntax' do
          expect(chef_run).to render_file(template.path).with_content(/module\(load="imfile"/)
        end

        it 'will include module parameter PollingInterval' do
          expect(chef_run).to render_file(template.path).with_content(/PollingInterval="10"/)
        end
        it 'is owned by root:root' do
          expect(template.owner).to eq('root')
          expect(template.group).to eq('root')
        end

        it 'has 0644 permissions' do
          expect(template.mode).to eq('0644')
        end

        it 'notifies restarting the service' do
          expect(template).to notify(service_resource).to(:restart)
        end
      end
    end
  end
end
