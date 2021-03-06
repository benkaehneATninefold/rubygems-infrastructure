#
# Cookbook Name:: rubygems-backups
# Recipe:: postgresql
#

include_recipe 'rubygems-backups::_common'

secrets = chef_vault_item('rubygems', node.chef_environment)
backup_secrets = chef_vault_item('secrets', 'backups')

template File.join(node['rubygems']['backups']['config_dir'], 'postgresql.rb') do
  source 'postgresql.rb.erb'
  owner 'root'
  group 'root'
  mode 00600
  variables(
    postgresql_db: "rubygems_#{node.chef_environment}",
    postgresql_user: secrets['rails_postgresql_user'],
    postgresql_password: node['postgresql']['password']['postgres'],
    gpg_email: backup_secrets['gpg_email'],
    gpg_public_key: backup_secrets['gpg_public_key'],
    aws_access_key: backup_secrets['aws_access_key'],
    aws_secret_key: backup_secrets['aws_secret_key'],
    bucket_name: 'rubygems-backups',
    slack_token: backup_secrets['slack_token']
  )
end

cron 'postgresql-backup' do
  hour '22'
  minute '22'
  day '*'
  month '*'
  weekday '*'
  command "backup perform --trigger postgresql --config-file #{File.join(node['rubygems']['backups']['config_dir'], 'postgresql.rb')}"
  user 'root'
end
