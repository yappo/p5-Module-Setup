package t::Flavor::WithAdditional;
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
---
additional: with
file: wadditional.txt
template: |
  additional wfile
---
additional: with
dir: waddir
---
additional: with
plugin: wadd.pm
template: |
  # null
