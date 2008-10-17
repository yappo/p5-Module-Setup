package t::Flavor::Simple;
use strict;
use warnings;
use base 'Module::Setup::Flavor';
1;

__DATA__

---
file: simple.txt
template: |
  [% module %]
