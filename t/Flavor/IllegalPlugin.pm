package t::Flavor::IllegalPlugin;
use strict;
use warnings;
use base 'Module::Setup::Flavor';
1;

__DATA__

---
config:
  plugins:
    - +IllegalPlugin
---
file: test.txt
template: |
  test text
---
plugin: illegalplugin.pm
template: |
  package IllegalPlugin;
  use strict;
  use warnings;

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
