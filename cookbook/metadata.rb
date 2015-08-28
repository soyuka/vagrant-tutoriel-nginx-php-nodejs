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
