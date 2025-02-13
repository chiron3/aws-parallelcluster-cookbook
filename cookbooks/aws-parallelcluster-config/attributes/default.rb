# aws-parallelcluster-config attributes

default['cluster']['raid_shared_dir'] = ''
default['cluster']['exported_raid_shared_dir'] = node['cluster']['raid_shared_dir']
default['cluster']['exported_intel_dir'] = '/opt/intel'

default['cluster']['scheduler_slots'] = 'vcpus'

default['cluster']['shared_storages_mapping_path'] = "/etc/parallelcluster/shared_storages_data.yaml"
default['cluster']['previous_shared_storages_mapping_path'] = "/etc/parallelcluster/previous_shared_storages_data.yaml"
