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

  $package_name = downcase("packer_${version}_${kernel}_${architecture}.zip")
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
  
  staging::file { $package_name: source => $full_url, } ->
  staging::extract { $package_name:
    target => $install_dir,
    creates => "${install_dir}/packer",
    require => File[$install_path],
  }
}
