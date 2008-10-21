package t::Flavor::IllegalPluginConfig;
use strict;
use warnings;
use base 'Module::Setup::Flavor';
1;

__DATA__

---
config:
  plugins:
    -
      - IllegalPluginConfig
---
file: test.txt
template: |
  test text
