package t::Helper::Basic;
use strict;
use warnings;
use base 'Module::Setup::Helper';

sub helper_option_prefix { 'test' }

1;

__DATA__

---
file: simple.txt
template: |
  [% module %]
  [% module_path %]
