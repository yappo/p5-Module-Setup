package t::Flavor::FlavorTest;
use base 'Module::Setup::Flavor';
1;
__DATA__

---
file: foo.txt
template: |
 local
---
plugin: foo.pm
template: |
  package local::foo;
  1;
---
dir: foo
---
config:
  foo: bar
---
foo: bar
