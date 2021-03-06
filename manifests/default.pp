group { 'puppet': ensure => present }
Exec { path => [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/', '/usr/local/bin' ] }
File { owner => 0, group => 0, mode => 0644 }

class {'apt':
  always_apt_update => true,
}

Class['::apt::update'] -> Package <|
    title != 'python-software-properties'
and title != 'software-properties-common'
|>

exec { "apt-update":
    command => "/usr/bin/apt-get update"
}

Exec["apt-update"] -> Package <| |>

    apt::key { '4F4EA0AAE5267A6C': }

apt::ppa { 'ppa:ondrej/php5-5.6':
  require => Apt::Key['4F4EA0AAE5267A6C']
}

class { 'puphpet::dotfiles': }

package { [
    'build-essential',
    'vim',
    'curl',
    'git-core',
    'git-flow',
    'memcached',
    'language-pack-pt',
    'htop'
  ]:
  ensure  => 'installed',
}

class { 'apache': }

apache::dotconf { 'custom':
  content => 
    'EnableSendfile Off

    <Directory /vhosts/>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
     </Directory>',
}

apache::module { 'rewrite': }

apache::vhost { 'phpsc.dev':
  server_name   => 'phpsc.dev',
  serveraliases => [
],
  docroot       => '/vhosts/phpsc.dev',
  port          => '80',
  env_variables => [
],
  priority      => '1',
}

class { 'php':
  service             => 'apache',
  service_autorestart => false,
  module_prefix       => '',
}

php::module { 'php5-mysqlnd': }
php::module { 'php5-cli': }
php::module { 'php5-curl': }
php::module { 'php5-intl': }
php::module { 'php5-mcrypt': }
php::module { 'php5-apcu': }
php::module { 'php5-imagick': }
php::module { 'php5-memcached': }
php::module { 'php5-readline': }

class { 'php::devel':
  require => Class['php'],
}

class { 'php::pear':
  require => Class['php'],
}


class { 'xdebug':
  service => 'apache',
}

class { 'composer':
  require => Package['php5', 'curl'],
}

puphpet::ini { 'xdebug-cli':
  value   => [
    'xdebug.default_enable = 0',
    'xdebug.remote_autostart = 0',
    'xdebug.remote_connect_back = 1',
    'xdebug.remote_enable = 1',
    'xdebug.remote_handler = "dbgp"',
    'xdebug.remote_port = 9000'
  ],
  ini     => '/etc/php5/cli/conf.d/zzz_xdebug.ini',
  notify  => Service['apache'],
  require => Class['php'],
}

puphpet::ini { 'xdebug-apache2':
  value   => [
    'xdebug.default_enable = 0',
    'xdebug.remote_autostart = 0',
    'xdebug.remote_connect_back = 1',
    'xdebug.remote_enable = 1',
    'xdebug.remote_handler = "dbgp"',
    'xdebug.remote_port = 9000'
  ],
  ini     => '/etc/php5/apache2/conf.d/zzz_xdebug.ini',
  notify  => Service['apache'],
  require => Class['php'],
}

puphpet::ini { 'php-cli':
  value   => [
    'date.timezone = "America/Sao_Paulo"',
    'always_populate_raw_post_data = -1'

  ],
  ini     => '/etc/php5/cli/conf.d/zzz_php.ini',
  notify  => Service['apache'],
  require => Class['php'],
}

puphpet::ini { 'php-apache2':
  value   => [
    'date.timezone = "America/Sao_Paulo"',
    'always_populate_raw_post_data = -1'

  ],
  ini     => '/etc/php5/apache2/conf.d/zzz_php.ini',
  notify  => Service['apache'],
  require => Class['php'],
}

puphpet::ini { 'custom-cli':
  value   => [
    'display_errors = On',
    'error_reporting = -1',
    'memory_limit = -1'
  ],
  ini     => '/etc/php5/cli/conf.d/zzz_custom.ini',
  notify  => Service['apache'],
  require => Class['php'],
}

puphpet::ini { 'custom-apache2':
  value   => [
    'display_errors = On',
    'error_reporting = -1',
    'memory_limit = -1'
  ],
  ini     => '/etc/php5/apache2/conf.d/zzz_custom.ini',
  notify  => Service['apache'],
  require => Class['php'],
}


class { 'mysql::server':
  config_hash   => {
    'root_password' => 'admin', 
    'character_set' => 'utf8mb4'
  }
}
