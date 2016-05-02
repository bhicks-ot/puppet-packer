class packer(
 $install_dir = $packer::params::install_dir,
 $base_url = $packer::params::base_url,
 $architecture = $::architecture,
 $kernel = $::kernel,
 $timeout = 600,
 $version,
) inherits packer::params {
  validate_absolute_path($install_dir)
  validate_string($base_url)
  validate_re($architecture, ['^amd64$', '^arm$', '^i386$' ])
  validate_re($kernel, ['^Linux$','^FreeBSD$','^OpenBSD$','^Windows$','^Darwin$'])
  validate_string($version)

  # packer version foreman is a numeric triple such as 0.6.1, 0.7.5, or 0.10.0
  $split_version = split($version, '[.]')

  # Explicitly set conditions based on the version number
  if ($split_version[0] == 0)  and 
     ($split_version[1] < 7) { # versions 0.0.0 through 0.6.x
    # package name and version call is different from default
    $package_name = downcase("${version}_${kernel}_${architecture}.zip")
    $version_check = '/opt/packer/bin/packer --version'

  } elsif ($split_version[0] == 0) and
          ($split_version[1] == 7) and
          ($split_version[2] <  5) { # versions 0.7.0 through 0.7.4
    # package name is same as default but version call is different
    $package_name = downcase("packer_${version}_${kernel}_${architecture}.zip")
    $version_check = '/opt/packer/bin/packer --version'
  }

  # the following should be the default conventions going forward (0.7.5 and higher)
  if $package_name == undef {
      $package_name = downcase("packer_${version}_${kernel}_${architecture}.zip")
  }
  if $version_check == undef {
      $version_check = '/opt/packer/bin/packer version'
  }

  # url to retrieve the packer installation package
  $full_url = "${base_url}/${package_name}"

  if !defined(Class['staging']) {
    class { 'staging':
      path => '/var/staging',
      owner => 'puppet',
      group => 'puppet',
    }
  }

  $install_path = dirtree($install_dir)
  file { $install_path: ensure => directory, }

  exec { 'check_version_change':
    path    => "/bin",
    command => "/usr/bin/test -f ${install_dir}/packer && rm ${install_dir}/packer*; return 0",
    unless  => "/bin/bash -c 'packer_version=\$($version_check | sed -nre \"s/^Packer v[^0-9]*(([0-9]+\\.)*[0-9]+).*/\\1/p\"); if [ \$packer_version = ${version} ]; then exit 0; else exit 1; fi'"
  } ->
  staging::file { $package_name: source => $full_url, } ->
  staging::extract { $package_name:
    target  => $install_dir,
    creates => "${install_dir}/packer",
    require => File[$install_path],
  }
}
