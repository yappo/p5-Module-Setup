package t::Plugin::AppendTemplateFile2;
use strict;
use warnings;
use base 'Module::Setup::Plugin';

sub register {
    my($self, ) = @_;
    $self->add_trigger( append_template_file => sub { $self->append_template_file(shift, 't::Plugin::AppendTemplateFile2Template') } );
}

1;

__DATA__

---
 file: append.txt
 template: |
  append
