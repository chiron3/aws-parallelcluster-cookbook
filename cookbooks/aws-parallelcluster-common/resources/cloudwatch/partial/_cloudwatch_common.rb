# frozen_string_literal: true

#
# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

unified_mode true
default_action :setup

action :setup do
  remote_file node['cluster']['cloudwatch']['public_key_local_path'] do
    source node['cluster']['cloudwatch']['public_key_url']
    retries 3
    retry_delay 5
    action :create_if_missing
  end

  # Set the s3 domain name to use for all download URLs
  s3_domain = "https://s3.#{node['cluster']['region']}.#{node['cluster']['aws_domain']}"

  # Set URLs used to download the package and expected signature based on platform
  package_url_prefix = "#{s3_domain}/amazoncloudwatch-agent-#{node['cluster']['region']}"
  arch_url_component = arm_instance? ? 'arm64' : 'amd64'
  Chef::Log.info("Platform for cloudwatch is #{platform_url_component}")
  package_url = [
    package_url_prefix,
    platform_url_component,
    arch_url_component,
    'latest',
    "amazon-cloudwatch-agent.#{package_extension}",
  ].join('/')
  signature_url = "#{package_url}.sig"
  signature_path = "#{package_path}.sig"

  # Download package and its expected signature
  remote_file signature_path do
    source signature_url
    retries 3
    retry_delay 5
    action :create_if_missing
  end
  remote_file package_path do
    source package_url
    retries 3
    retry_delay 5
    action :create_if_missing
  end

  # Import cloudwatch agent's public key to the keyring
  execute 'import-cloudwatch-agent-key' do
    command "gpg --import #{node['cluster']['cloudwatch']['public_key_local_path']}"
  end

  # Verify that cloudwatch agent's public key has expected fingerprint
  execute 'verify-cloudwatch-agent-public-key-fingerprint' do
    command 'gpg --list-keys --fingerprint "Amazon CloudWatch Agent" | grep "9376 16F3 450B 7D80 6CBD  9725 D581 6730 3B78 9C72"'
  end

  # Verify that the cloudwatch agent package matches its expected signature
  execute 'verify-cloudwatch-agent-rpm-signature' do
    command "gpg --verify #{signature_path} #{package_path}"
  end

  action_cloudwatch_install_package
end

action_class do
  def package_path
    "#{node['cluster']['sources_dir']}/amazon-cloudwatch-agent.#{package_extension}"
  end
end

action :configure do
  config_script_path = '/usr/local/bin/write_cloudwatch_agent_json.py'
  cookbook_file 'write_cloudwatch_agent_json.py' do
    action :create_if_missing
    source 'cloudwatch/write_cloudwatch_agent_json.py'
    path config_script_path
    user 'root'
    group 'root'
    mode '0755'
  end

  config_data_path = '/usr/local/etc/cloudwatch_agent_config.json'
  cookbook_file 'cloudwatch_agent_config.json' do
    action :create_if_missing
    source 'cloudwatch/cloudwatch_agent_config.json'
    path config_data_path
    user 'root'
    group 'root'
    mode '0644'
  end

  config_schema_path = '/usr/local/etc/cloudwatch_agent_config_schema.json'
  cookbook_file 'cloudwatch_agent_config_schema.json' do
    action :create_if_missing
    source 'cloudwatch/cloudwatch_agent_config_schema.json'
    path config_schema_path
    user 'root'
    group 'root'
    mode '0644'
  end

  validator_script_path = '/usr/local/bin/cloudwatch_agent_config_util.py'
  cookbook_file 'cloudwatch_agent_config_util.py' do
    action :create_if_missing
    source 'cloudwatch/cloudwatch_agent_config_util.py'
    path validator_script_path
    user 'root'
    group 'root'
    mode '0644'
  end

  if redhat_ubi?
    node.override!['cluster']['cookbook_virtualenv_path'] = '/usr'
    node.override!['cluster']['node_virtualenv_path'] = '/usr'
    node.override!['cluster']['awsbatch_virtualenv_path'] = '/usr'
    node.override!['cluster']['cfn_bootstrap_virtualenv_path'] = '/usr'
  end

  execute "cloudwatch-config-validation" do
    user 'root'
    timeout 300
    environment(
      'CW_LOGS_CONFIGS_SCHEMA_PATH' => config_schema_path,
      'CW_LOGS_CONFIGS_PATH' => config_data_path
    )
    command "#{cookbook_virtualenv_path}/bin/python #{validator_script_path}"
  end

  execute "cloudwatch-config-creation" do
    user 'root'
    timeout 300
    environment(
      'LOG_GROUP_NAME' => node['cluster']['log_group_name'],
      'SCHEDULER' => node['cluster']['scheduler'],
      'NODE_ROLE' => node['cluster']['node_type'],
      'CONFIG_DATA_PATH' => config_data_path
    )
    not_if { ::File.exist?('/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json') }

    cluster_config_path = node['cluster']['scheduler'] == 'plugin' ? "--cluster-config-path #{node['cluster']['cluster_config_path']}" : ""

    command "#{cookbook_virtualenv_path}/bin/python #{config_script_path} "\
        "--platform #{node['platform']} --config $CONFIG_DATA_PATH --log-group $LOG_GROUP_NAME "\
        "--scheduler $SCHEDULER --node-role $NODE_ROLE #{cluster_config_path}"
  end

  execute "cloudwatch-agent-start" do
    user 'root'
    timeout 300
    command "/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s"
    not_if do
      system("/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status | grep status | grep running") ||
        node['cluster']['cw_logging_enabled'] != 'true' ||
        virtualized?
    end
  end
end
