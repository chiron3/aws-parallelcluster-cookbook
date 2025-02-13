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

action :download_and_install do
  mysql_archive_url = package_archive(node['cluster']['artifacts_s3_url'])
  mysql_tar_file = "/tmp/#{package_filename}"

  log "Downloading MySQL packages archive from #{mysql_archive_url}"

  remote_file mysql_tar_file do
    source mysql_archive_url
    mode '0644'
    retries 3
    retry_delay 5
    action :create_if_missing
  end

  bash 'Install MySQL packages' do
    user 'root'
    group 'root'
    cwd '/tmp'
    code <<-MYSQL
        set -e

        EXTRACT_DIR=$(mktemp -d --tmpdir mysql.XXXXXXX)
        tar xf "#{mysql_tar_file}" --directory "${EXTRACT_DIR}"
        yum install -y ${EXTRACT_DIR}/*
    MYSQL
  end
end
