# Amazon Linux 2 default attributes for aws-parallelcluster-install

return unless platform?('amazon') && node['platform_version'] == "2"

# environment-modules required by EFA, Intel MPI and ARM PL
# iptables needed for IMDS setup
default['cluster']['base_packages'] = %w(vim ksh tcsh zsh openssl-devel ncurses-devel pam-devel net-tools openmotif-devel
                                         libXmu-devel hwloc-devel libdb-devel tcl-devel automake autoconf pyparted libtool
                                         httpd boost-devel system-lsb mlocate atlas-devel glibc-static iproute
                                         libffi-devel dkms libedit-devel postgresql-devel postgresql-server
                                         sendmail cmake byacc libglvnd-devel mdadm libgcrypt-devel libevent-devel
                                         libxml2-devel perl-devel tar gzip bison flex gcc gcc-c++ patch
                                         rpm-build rpm-sign system-rpm-config cscope ctags diffstat doxygen elfutils
                                         gcc-gfortran git indent intltool patchutils rcs subversion swig systemtap curl
                                         jq wget python-pip NetworkManager-config-routing-rules libibverbs-utils
                                         librdmacm-utils python3 python3-pip iptables libcurl-devel yum-plugin-versionlock
                                         coreutils moreutils environment-modules bzip2)

# Install R via amazon linux extras
default['cluster']['extra_packages'] = ['R3.4']

default['cluster']['kernel_devel_pkg']['name'] = "kernel-devel"
default['cluster']['kernel_devel_pkg']['version'] = node['kernel']['release']

default['cluster']['chrony']['conf'] = "/etc/chrony.conf"
