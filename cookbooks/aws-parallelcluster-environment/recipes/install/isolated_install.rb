# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: base_isolated
#
# Copyright:: 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

directory node['cluster']['scripts_dir'] do
  recursive true
end

template "#{node['cluster']['scripts_dir']}/patch-iso-instance.sh" do
  source 'isolated/patch-iso-instance.sh.erb'
  owner 'root'
  group 'root'
  mode '0744'
  variables(
    users: ['root', node['cluster']['cluster_admin_user'], node['cluster']['cluster_user']].join(' ')
  )
end
