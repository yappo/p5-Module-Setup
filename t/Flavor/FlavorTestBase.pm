package t::Flavor::FlavorTestBase;
use base 'Module::Setup::Flavor';
1;
__DATA__

---
file: foo.txt
template: |
  base
---
plugin: foo.pm
template: |
  package base::foo;
  1;
---
dir: foo
---
file: bar.txt
template: |
  base
---
plugin: bar.pm
template: |
  package base::bar;
  1;
---
dir: bar
---
config:
  bar: baz
---
bar: baz
