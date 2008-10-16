package t::Flavor::LocalPlugin;
use strict;
use warnings;
use base 'Module::Setup::Flavor';
1;

__DATA__

---
config:
  plugins:
    - +LocalPlugin
---
file: test.txt
template: |
  test text
---
plugin: localplugin.pm
template: |
  package LocalPlugin;
  use strict;
  use warnings;
  use base 'Module::Setup::Plugin';

  sub register {
      my($self, ) = @_;
      $self->add_trigger( append_template_file => sub { $self->append_template_file(@_) } );
  }

  1;

  __DATA__

  ---
  file: append.txt
  template: |
    append
