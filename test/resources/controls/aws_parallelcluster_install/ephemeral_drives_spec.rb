# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

control 'tag:install_ephemeral_drives_logical_volumes_manager_installed' do
  title 'Check ephemeral drives management utility is installed'

  describe package('lvm2') do
    it { should be_installed }
  end
end

control 'tag:install_ephemeral_drives_script_created' do
  title 'Ephemeral drives script is copied to the target dir'

  describe file('/usr/local/sbin/setup-ephemeral-drives.sh') do
    it { should exist }
    its('mode') { should cmp '0744' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('content') { should_not be_empty }
  end
end

control 'tag:install_ephemeral_service_set_up' do
  title 'Ephemeral service is set up to run ephemeral drives script'

  describe file('/etc/systemd/system/setup-ephemeral.service') do
    it { should exist }
    its('mode') { should cmp '0644' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('content') { should match 'ExecStart=/usr/local/sbin/setup-ephemeral-drives.sh' }
  end
end

control 'tag:install_ephemeral_service_after_network_config' do
  title 'Check setup-ephemeral service to have the correct After statement'
  network_target = os_properties.redhat? ? /^After=network-online.target/ : /^After=network.target$/
  describe file('/etc/systemd/system/setup-ephemeral.service') do
    it { should exist }
    its('content') { should match network_target }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0644' }
  end
end
