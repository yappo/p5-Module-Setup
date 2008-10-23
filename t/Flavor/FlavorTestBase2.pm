package t::Flavor::FlavorTestBase2;
use base 'Module::Setup::Flavor';
1;
__DATA__

---
file: foo.txt
template: |
  base2
---
file: base2.txt
template: |
  nya-mo
---
config:
  base2: baz

