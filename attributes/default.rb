#
# Cookbook: consul_template
# License: MIT
#
# Copyright 2016, Vision Critical Inc.
#
default['consul_template']['service_name'] = 'consul-template'
default['consul_template']['version'] = '0.19.4'

default['consul_template']['config']['conf_dir'] = conf_dir
default['consul_template']['config']['template_dir'] = template_dir
# https://github.com/hashicorp/consul-template#options
default['consul_template']['config']['options'] = {}

default['consul_template']['service']['data_dir'] = data_dir
# Linux only
default['consul_template']['service']['environment'] = {}
default['consul_template']['service']['user']  = 'consul-template'
default['consul_template']['service']['group'] = 'consul-template'
# Windows only
default['consul_template']['service']['nssm_params'] = {
  'AppDirectory'     => conf_dir,
  'AppStdout'        => join_path(install_path,'logs','log.txt'),
  'AppStderr'        => join_path(install_path,'logs','error.txt'),
  'AppRotateFiles'   => 0,
  'AppRotateOnline'  => 0,
  'AppRotateBytes'   => 0
}

###
# Noteworthy Overrides
###
# default['consul_template']['archive_url']
# default['consul_template']['install_path']
# default['consul_template']['service']['program']
# default['poise-service']['consul-template']['template'] = 'cookbook:erb_file'
