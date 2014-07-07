name "omero"
maintainer "Stephen Crawley"
maintainer_email "s.crawley at uq dot edu dot au"
license "BSD"
description "Recipes for installing Omero server"
version "0.5.5"
supports "ubuntu", ">= 14.04"
supports "fedora", ">= 16"
%w{redhat centos scientific}.each do |el|
  supports el, "6.5"
end

depends "java", ">= 1.13.0"
depends "python"
depends "postgresql"
depends "apache"
depends "nginx"

