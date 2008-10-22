package t::Plugin::AdditionalCheck;
use strict;
use warnings;
use base 'Module::Setup::Plugin';

sub register {
    my($self, ) = @_;
    $self->add_trigger( after_create_skeleton => sub { $self->after_create_skeleton(@_) } );
}

sub after_create_skeleton {}
1;
