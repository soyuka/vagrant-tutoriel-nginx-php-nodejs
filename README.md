Dans ce tutoriel nous allons créer un environnement de développement avec Vagrant. Nous allons y configurer nodejs et php avec nginx.  
  
## Disclaimer
  
Si vous n'avez pas un minimum de connaissances linux ce tutoriel n'est malheureusement pas pour vous. Il s'adresse à un public avancé.   
Je suis un fan de la doctrine RTFM , et pour cause j'ajouterai souvent un lien vers la documentation lié à la tâche en cours. Utilisez ces liens à bon escient, ou juste par curiosité. Si vous exécutez ce tutoriel juste en faisant des copier/coller vous n'apprendrez pas grand chose.  
  
## C'est quoi Vagrant ?
  
[Vagrant][0] est un logiciel multi plateforme qui permet de créer et configurer des environnement "reproductibles, portables et légers". Imaginez que c'est un outil de création de machines virtuelles. Le must c'est que Vagrant s'occupe de pleins de choses tout seul : réseau, dossier partagé nfs, providers, déploiements etc. Nous n'allons couvrir qu'une toute petite partie des features de Vagrant à savoir :  
- Ajouter des providers basiques  
- Utiliser chef solo avec [Berkshelf][1] (un gestionnaire de cookbooks)  
- Installer un plugin vagrant pour gérer les hosts (bon à savoir il existe une [pléiade de plugins][2])  
  
Pour en savoir plus allez faire un tour sur la [documentation de Vagrant][3].  
La liste des commandes principales :  
  
```
vagrant --help
```   
  
## C'est quoi Chef ?
  
[Chef][4] est ce que Vagrant appelle un "Provisionner". En gros, c'est un outil (super ultra trop beaucoup puissant) qui permet d'installer et de configurer des environnements. Nous pouvons le comparer avec son homonyme [Puppet][5], voir le système plus léger qu'est [Ansible][6].   
Chef est très (trop ?) puissant. Je trouve que quand on essaie de comprendre son fonctionnement sans contexte c'est très difficile et peut en freiner beaucoup. Ici nous allons utiliser [chef-solo][7] ([documentation vagrant][8]). C'est une version open source du client Chef qui peut être installé localement (sans serveur Chef). Il va nous servir à profiter de quelques 2416 recettes (plus communément appelées "cookbooks").   
  
  
## À quoi ça sert tout ça ?
  
Grâce à Vagrant vous pouvez ensuite partager votre box, box qui n'est conçue que de fichiers de configuration. Très pratique quand plusieurs développeurs veulent avoir le même environnement sur lequel travailler. Ou par exemple pour lancer des tests sur Debian, ubuntu et centos en même temps depuis une seule machine avec une seule configuration !   
De plus les instructions qui suivent devraient être les mêmes sous linux, windows et osx !  
  
Maintenant que nous sommes dans le bain, ou plutôt la soupe, nous allons établir un plan d'action.   
  
## À l'attaque !
  
### Nos besoins :
  
- Debian  
- Nodejs  
- Php  
- Nginx  
  
### Nos prérequis :
  
- [Installer Vagrant][9]  
- [Installer VirtualBox][10]  
- [Installer ChefDK (development kit)][11]  
  
### Plan :
  
1. Créér une box de base  
2. Instancier nos cookbooks avec Berkshelf  
3. Mettre en place le cookbook perso  
4. Configurer Vagrant avec le Vagrantfile  
5. Observer la magie à l'oeuvre  
6. Cerise sur le gâteau  
7. Trucs et astuces  
8. Ressources  
  
## 1. Créer une box de base
  
/?\ Au préalable placez vous dans un répertoire de travail  
  
Pour ce faire direction [Vagrant boxes][12]. C'est la liste officielle de Vagrant. Il existe d'autres sites du genre (ex :[http://www.vagrantbox.es/][13]). Attention n'utilisez pas n'importe laquelle sans au préalable vérifier ce qu'elle contient !   
  
Ca me rappelle d'ailleurs un bon article sur les conteneurs (ou box):  

> And since nobody is still able to compile things from scratch, **everybody just downloads precompiled binaries from random websites**. Often **without any authentication or signature**. NSA and virus heaven. **You don't need to exploit any security hole anymore.** Just make an "app" or "VM" or "Docker" image, and have people load your malicious binary to their network.

_[The sad state of sysadmin in the age of containers][14]_.  
  
Parenthèse fermée, j'ai la box qu'il nous faut : [debian/jessie64][15] et pour lancer la notre :  
  
```   
vagrant init debian/jessie64
```   
  
Cette commande nous créé un fichier de configuration, le fameux "VagrantFile". Eh oui c'est tout, je sens beaucoup de déception. Pas d'inquiétude ce n'est que le commencement, la magie ne se fera pas longtemps attendre.  
  
/?\ Si vous êtes impatient, lancez la commande suivante pour télécharger la box et l'installer :  

```
vagrant up
```
  
Lorsqu'on aura édité les configurations il faudra utiliser la commande suivante pour provisioner à nouveau :  

```
vagrant provision
```
  
## 2. Instancier nos cookbooks avec Berkshelf 
  
Comme dit plus haut, nous allons utiliser Berkshelf, pour gérer les cookbooks Chef. Il faut donc installer le plugin :  
  
```
vagrant plugin install vagrant-berkshelf
```
  
/!\ Vous aurez besoin de [ChefDK][11] pour l'installer  
  
Ensuite, on ajoute un fichier de configuration contenant nos cookbooks :  
  
```
vim Berksfile
```    
  
Ajoutez-y la liste suivante :  

```
source 'https://supermarket.chef.io'

cookbook 'apt'
cookbook 'build-essential'
cookbook 'nvm'
cookbook 'php'
cookbook 'nginx'
cookbook 'perso', path: './cookbook'
```   

Vous trouverez les cookbooks sur le [supermarché Chef][16]. Voir aussi les ["officiels"][17].  
Notez le dernier cookbook, il représente le chemin où nous allons placer nos recettes perso :).  
  
## 3. Créer un cookbook perso
  
Nous allons créer une petite structure avec des cookbooks chef. Ils seront très basiques et écris en ruby (comme l'est le Vagrantfile d'ailleurs).  
  
### Créer la structure globale :
    
```bash
#share sera notre répertoire partagé
mkdir -p cookbook/recipes cookbook/templates/default share
touch cookbook/Berksfile cookbook/metadata.rb
```
  
/!\ Celle-ci n'est qu'un exemple, c'est une structure basique d'un cookbook chef ([https://docs.chef.io/index.html\#Cookbooks][18]).  
  
Dans le `metadata.rb` nous aurons quelque chose comme ca :  
    
```ruby
name 'perso'
maintainer 'soyuka'
maintainer_email 'trucmuche@gmail.com'
description 'Une super box vagrant de la mort qui tue'
version '1.0.0'

recipe 'perso', 'Mon cookbook perso'

depends 'apt'
depends 'nvm'
depends 'nginx'
depends 'php'

%W{ debian ubuntu }.each do |os|
supports os
end
```
  
Dans le Berksfile :  
  
```ruby
source 'https://supermarket.chef.io'

metadata #il va lire notre metadata
```
  
### Recette pour nos paquets :
  
Première recette toute basique qui va nous servir à installer des paquets depuis la configuration.  
  
La configuration est en fait la configuration chef que nous allons créer dans notre Vagrantfile. Chaque nœud de celle-ci se retrouve ensuite dans la variable globale "node".  
  
Créez le fichier `cookbook/recipes/packages.rb` avec comme contenu :  
  
```ruby
include_recipe 'apt'

# Pour chaque paquet on l'installe (apt-get install [paquet])
node['perso']['packages'].each do |a_package|
  package a_package
end
```
  
### Recette pour nodejs (via nvm) :

Dans le fichier `cookbook/recipes/nodejs.rb` :  

```ruby
include_recipe 'nvm'

nvm_install 'v0.12.7' do
  user 'vagrant'
  group 'vagrant'
  from_source false
  alias_as_default true
  action :create
end

# Pour chaque paquet `npm install -g [paquet]`
node['perso']['npm_packages'].each do |n_package|
  script n_package do 
    interpreter 'bash'
    cwd '/home/vagrant'
    code "su vagrant -l -c 'npm install #{n_package} -g'"
    # Ne pas installer si déjà présent
    not_if "su vagrant -l -c 'npm list --depth=0 -g #{n_package}'"
  end
end
```    
  
### Recette pour php-fpm :

Dans `cookbook/recipes/php.rb` :
    
```ruby
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
```

### Recette pour nginx :
      
Ajoutons d'abord notre template de vhost dans `cookbook/templates/default/nginx/perso` :  

```nginx
server {
        listen 80;
        listen [::]:80 ipv6only=on;
        
        root /var/www/perso;

        server_name localhost;
        index index.php;
        access_log /var/log/nginx/perso-access.log;
        error_log /var/log/nginx/perso-error.log notice;


        location ~ \.php$ {
                try_files $uri =404;
                fastcgi_pass unix:/var/run/php5-fpm.sock;
                fastcgi_index index.php;
                fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                include /etc/nginx/fastcgi_params;
        }
}
```


/?\ Il est possible d'ajouter des variables à ce genre de templates, [un exemple avec un vhost apache][19].  

Dans **cookbook/recipes/nginx.rb** :  

```ruby
include_recipe "nginx"

# On utilise notre template
template '/etc/nginx/sites-available/perso' do
  source 'nginx/perso'
end

nginx_site 'perso' do
  enable true
  notifies :restart, 'service[nginx]'
end

# J'ai un bug avec le restart mais stop/start fonctionne bien :)
service 'php5-fpm' do
  action :stop
  action :start
end
```

Pour le test on aura besoin d'un fichier php. Ici pas besoin d'un template on va simplement utiliser notre répertoire partagé ! Ajoutez dans le fichier `share/index.php` :  

```php<?php phpinfo(); ?>```

#### Aller plus loin :

/?\ Vous pouvez aisément ajouter des recettes "inline" via le shell dans le Vagrantfile. Pour ce faire il suffit d'utiliser des "shell provisioners" ([documentation][20]), par exemple :  

```ruby
config.vm.provision :shell, :inline => "apt-get update"
```

Bien entendu celui-ci est inutile car le cookbook `apt` se charge déjà de ca pour nous !  

## 4. Configurer Vagrant avec le Vagrantfile

Voici ma config, lisez les commentaires et modifiez la ram utilisée (surtout si vous avez en dessous de 4gb de libre pour la vm :P).  

```ruby
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

  # Setup de l'ip par rapport aux paramètres globaux
  config.vm.hostname = project_name + '.local'        
  config.vm.network :private_network, ip: ip_address

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
```

## 5. Observer la magie à l'oeuvre

Lancez votre vagrant :  

```bash
vagrant up
```

Quand c'est fini, ouvrez "[http://192.168.33.10/][21]" sur votre navigateur, vous devriez voir le `phpinfo()` !  

Même pas besoin de se connecter à la box pour modifier les fichiers, utilisez votre éditeur préféré dans notre dossier `share` :D.  

Si vous voulez faire des vérifications, ou rapidement vérifier qu'un changement de configuration fonctionnera au prochain `vagrant provision`, vous pouvez vous connecter en ssh avec :  

```bash
vagrant ssh
#puis on peut vérifier que tout est bien installé par ex :
node -v
pm2 -v
```

## 6. La cerise sur le gâteau

Si on veut gérer plusieurs box, où même par question de simplicité, avoir une gestion des hosts serait un plus non négligeable !  
La bonne nouvelle c'est que ca existe en plugin Vagrant :D !  

```bash
vagrant plugin install vagrant-hostmanager
```

Éditons le VagrantFile afin de remplacer juste après `config.berkshelf.enabled` :  

```ruby
# Configuration du host manager
config.hostmanager.enabled = true
config.hostmanager.manage_host = true

# Setup de l'ip par rapport aux paramètres globaux
config.vm.hostname = project_name + '.local'        
config.vm.network :private_network, ip: ip_address
config.hostmanager.aliases = [ "www." + project_name + ".local" ]

config.vm.provision :hostmanager
```

Il suffit maintenant de provisionner à nouveau la box :  

```bash
vagrant provision
```

Et maintenant vous avez accès à la box sur "[http://perso.local][22]" !  

/?\ Pour ne pas avoir à saisir de mot de passe lorsque vagrant modifie votre fichier `hosts` utilisez [cette astuce][23]  

## 7. Trucs et astuces

### Dotdeb pour debian 7

Je ne sais pas vous mais moi j'aime php 5.4, sa notation de tableaux raccourcie et son serveur de développement intégré. Et vu qu'ils nous en faut toujours plus on veut la version php 5.5 !  
Sur Debian 7, elles ne sont pas dans les dépôts par défaut, mais on peut ajouter dotdeb :).  

Le cookbook ressemble à ca :  

```ruby
include_recipe "apt"

apt_repository "dotdeb-php55" do
  uri "http//packages.dotdeb.org"
  distribution "wheezy-php55"
  components ["all"]
  key "http//www.dotdeb.org/dotdeb.gpg"
end
```

Nous ne pouvions faire plus simple. Ici, on utilise la fonction [apt_repository du cookbook apt][24]. Cookbook qu'on a ajouté avant à notre Berksfile :).  

### Bug de nfs avec Apache/Nginx et VirtualBox

Il y a un bug avec VirtualBox et les fichiers statiques (cache ou que sais-je [voir là][25]). Pour le fixer ajoutez les directives suivantes en fonction de votre serveur web :  

- Apache: `EnableSendfile off`
- Nginx : `sendfile off;`

### Installer composer

Pour ce faire, le script est une bonne solution :  

```bash

script 'install_composer' do
  interpreter "bash"
  code <<-EOH
    curl -s https://getcomposer.org/installer | php
    mv composer.phar /usr/local/bin/composer && chmod +x /usr/local/bin/composer
  EOH
  not_if { ::File.exists?("/usr/local/bin/composer")}
end
```

## 8. Resources :
        
- [https://docs.chef.io/resource_examples.html][26] Bouts de codes utiles pour les recettes  
- [https://scotch.io/tutorials/get-vagrant-up-and-running-in-no-time][27] C'est le tuto qui m'a le plus aidé pour comprendre les bases  
- [https://github.com/scotch-io/Vagrant-LAMP-Stack/][28] fork de [https://github.com/MiniCodeMonkey/Vagrant-LAMP-Stack][29] De bonnes idées de structures même s'il faut forcément repasser derrière pour en avoir un à sa sauce  
- [http://stackoverflow.com/questions/9479117/vagrant-virtualbox-apache2-strange-cache-behaviour][25] Bug de Virtualbox avec _sendfile on;_  
- [https://supermarket.chef.io/cookbooks][16] Le supermarché où vous trouverez les documentations pour les cookbooks utilisés dans le tuto (nginx, php, nvm)  
- [https://docs.vagrantup.com/v2/][3] La documentation de vagrant  
- [https://github.com/mitchellh/vagrant/wiki/Available-Vagrant-Plugins][2] Liste de plugins vagrant  


[0]: https://www.vagrantup.com/
[1]: http://berkshelf.com/
[2]: https://github.com/mitchellh/vagrant/wiki/Available-Vagrant-Plugins
[3]: https://docs.vagrantup.com/v2/
[4]: https://www.chef.io/
[5]: https://puppetlabs.com/
[6]: http://www.ansible.com/home
[7]: https://docs.chef.io/chef_solo.html
[8]: http://docs.vagrantup.com/v2/provisioning/chef_solo.html
[9]: https://www.vagrantup.com/downloads.html
[10]: https://www.virtualbox.org/wiki/Downloads
[11]: https://downloads.chef.io/chef-dk/
[12]: https://atlas.hashicorp.com/boxes/search
[13]: http://www.vagrantbox.es/
[14]: http://www.vitavonni.de/blog/201503/2015031201-the-sad-state-of-sysadmin-in-the-age-of-containers.html
[15]: https://atlas.hashicorp.com/debian/boxes/jessie64
[16]: https://supermarket.chef.io/cookbooks
[17]: https://github.com/opscode-cookbooks
[18]: https://docs.chef.io/index.html#Cookbooks
[19]: https://github.com/scotch-io/Vagrant-LAMP-Stack/blob/master/site-cookbooks/app/templates/default/web_app.conf.erb
[20]: https://docs.vagrantup.com/v2/provisioning/shell.html
[21]: http://192.168.33.10/
[22]: http://perso.local
[23]: https://github.com/smdahlen/vagrant-hostmanager#passwordless-sudo
[24]: https://github.com/opscode-cookbooks/apt#apt_repository
[25]: http://stackoverflow.com/questions/9479117/vagrant-virtualbox-apache2-strange-cache-behaviour
[26]: https://docs.chef.io/resource_examples.html
[27]: https://scotch.io/tutorials/get-vagrant-up-and-running-in-no-time
[28]: https://github.com/scotch-io/Vagrant-LAMP-Stack/
[29]: https://github.com/MiniCodeMonkey/Vagrant-LAMP-Stack
