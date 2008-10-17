package t::Plugin::AppendTemplateFile;
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
 chmod: 0611
 template: |
  append
---
 dir: add
---
 config:
  foo: bar
