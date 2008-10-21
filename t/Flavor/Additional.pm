package t::Flavor::Additional;
use strict;
use warnings;
use base 'Module::Setup::Flavor';
1;

__DATA__

---
file: additional.txt
template: |
  additional file
---
dir: addir
---
plugin: add.pm
template: |
  # null
