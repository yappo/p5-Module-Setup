package t::Helper::Basic::Foo;
use strict;
use warnings;
use base 't::Helper::Basic';

sub generate_path_option_names { qw/ target / }
sub is_append_files { 1 }

1;

__DATA__

---
file: simple.txt
template: |
  [% module %]
  [% module_path %]
  [% test_target %]
  [% test_target_path %]
