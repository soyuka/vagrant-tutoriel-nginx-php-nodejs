include_recipe 'php'

php_fpm_pool 'default' do
  action :install
end

# Php met à jour uniquement la directive dans /etc/php5/cli/php.ini
# https://github.com/opscode-cookbooks/php/issues/116
script 'copy_php.ini' do
  interpreter "bash"
  user 'root'
  code <<-EOH
    cp /etc/php5/cli/php.ini /etc/php5/fpm/php.ini
  EOH
  only_if { ::File.exist?('/etc/php5/cli/php.ini') }
end
