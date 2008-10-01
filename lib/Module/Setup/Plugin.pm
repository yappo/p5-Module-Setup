package Module::Setup::Plugin;
use strict;
use warnings;

sub base_class { shift->{base_class} }

sub new {
    my($class, %args) = @_;
    $args{base_class} ||= 'Module::Setup';
    my $self = bless { %args }, $class;
    $self->register;
    $self;
}

sub register {}

sub add_trigger {
    my($self, @args) = @_;
    $self->base_class->add_trigger(@args);
}

1;
