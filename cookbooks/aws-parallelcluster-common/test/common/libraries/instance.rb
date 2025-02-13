class Instance < Inspec.resource(1)
  name 'instance'

  desc '
    Instance properties
  '
  example '
    instance.graphic?
  '

  def head_node?
    inspec.node['cluster']['node_type'] == 'HeadNode'
  end

  def compute_node?
    inspec.node['cluster']['node_type'] == 'ComputeFleet'
  end

  def dcgmi_gpu_accel_supported?
    unsupported_gpu_accel_list = ["g2."]
    !inspec.node['ec2']['instance_type'].start_with?(*unsupported_gpu_accel_list)
  end

  def gpudirect_rdma_supported?
    unsupported_gpudirect_rdma_list = ["g2."]
    !inspec.node['ec2']['instance_type'].start_with?(*unsupported_gpudirect_rdma_list)
  end

  def dcv_gpu_accel_supported?
    unsupported_gpu_accel_list = ["g5g."]
    !inspec.node['ec2']['instance_type'].start_with?(*unsupported_gpu_accel_list)
  end

  def efa_supported?
    !inspec.os_properties.arm? || !inspec.node['cluster']['efa']['unsupported_aarch64_oses'].include?(inspec.node['cluster']['base_os'])
  end

  def imds_token
    @imds_token = inspec.http('http://169.254.169.254/latest/api/token', method: 'PUT', headers: {
      "X-aws-ec2-metadata-token-ttl-seconds": 900,
    }).body unless @imds_token
    @imds_token
  end

  def imds(what)
    inspec.http("http://169.254.169.254/latest/#{what}", headers: {
      "X-aws-ec2-metadata-token": imds_token,
    }).body
  end

  def graphic?
    !inspec.command("lspci | grep -i -o 'NVIDIA'").stdout.strip.empty?
  end

  def nvs_switch_enabled?
    inspec.command("lspci -d 10de:1af1 | wc -l").stdout.strip.to_i > 1
  end

  def custom_ami?
    inspec.node['cluster']['os'] && inspec.node['cluster']['os'].end_with?("-custom")
  end

  def nvidia_installed?
    inspec.file('/usr/bin/nvidia-smi').exist?
  end

  def get_ephemeral_devs
    ephemeral_devs = []
    if inspec.bash('ls /dev/nvme*').exit_status() == 0
      ephemeral_devs += inspec.bash('realpath --relative-to=/dev/ -P /dev/disk/by-id/nvme*Instance_Storage* | grep -v "*Instance_Storage*" | uniq').stdout.split(/\n+/)
    else
      imds('block-device-mapping').split(/\n+/).each do |device|
        if device.match(/ephemeral/)
          ephemeral_devs += imds("block-device-mapping/#{device}").gsub('sd', 'xvd')
        end
      end
    end
    ephemeral_devs
  end
end
