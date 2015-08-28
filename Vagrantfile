# -*- mode: ruby -*-
# vi: set ft=ruby :

# Ici je met des paramètres 'globaux' (pour plus tard)
ip_address = '192.168.33.10'
project_name = 'perso'

Vagrant.configure(2) do |config|
  config.vm.box = 'debian/jessie64'
  # Vagrant va chercher sur l'url officielle de base mais c'est ici que vous pouvez mettre des box custom
  config.vm.box_url = 'debian/jessie64'

  # Le répertoire partagé (magie, ou presque...)
  config.vm.synced_folder './share', '/var/www/perso/', :mount_options => ['dmode=777', 'fmode=666']

  config.vm.provider 'virtualbox' do |vb|
   # Ici on demande à Vagrant de nous ouvrir la VirtualBox, pratique pour vérifier que le boot s'effectue bien
   # Si on déploie ou partage la box on peut aisément le désactiver
    vb.gui = true 
   # Mettez max 1/4 de votre ram au cas où, plus pourrait nuire à votre système
    vb.memory = '4024'
    # d'autres options : https://docs.vagrantup.com/v2/virtualbox/configuration.html
  end

  # Activation de berkshelf
  config.berkshelf.enabled = true

  # Configuration du host manager
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true

  # Setup de l'ip par rapport aux paramètres globaux
  config.vm.hostname = project_name + '.local'        
  config.vm.network :private_network, ip: ip_address
  config.hostmanager.aliases = [ "www." + project_name + ".local" ]

  config.vm.provision :hostmanager

  # Enfin notre configuration chef pour les recettes !
  config.vm.provision :chef_solo do |chef|
    # Ici on appelle nos cookbooks chef :)
    chef.add_recipe 'apt'
    # toujours utile car on pourrait avoir besoin de compiler une extension php par exemple
    chef.add_recipe 'build-essential'
    chef.add_recipe 'perso::packages'
    chef.add_recipe 'perso::nodejs'
    chef.add_recipe 'perso::php'
    chef.add_recipe 'perso::nginx'
    
    # La c'est la configuration des paquets dont je parle plus haut (variable node)
    chef.json = {
      :perso => {
        :packages => %W{ vim git curl httpie jq }, # Mettez ceux que vous voulez :)
        :npm_packages => %W{ gulp mocha bower pm2 }
      },
      :php => {
         # On ajoute ca au .ini (voir https://github.com/opscode-cookbooks/php#attributes)
        :directives => {
          'date.timezone' => 'Europe/Paris'
        },
        :fpm_user => 'vagrant',
        :fpm_group => 'vagrant'
      },
      :nginx => {
        :user => 'vagrant',
        :default_site_enabled => false,
        :sendfile => 'off' # à cause d'un bug de VirtualBox
      }
    }
  end
end
