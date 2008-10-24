package Module::Setup::Plugin::Config::Basic;
use strict;
use warnings;
use base 'Module::Setup::Plugin';

sub register {
    my($self, ) = @_;
    $self->add_trigger( before_dump_config => \&before_dump_config );
}

sub before_dump_config {
    my($self, $config) = @_;

    $config->{author} ||= 'Default Name';
    $config->{author} = $self->dialog("Your name: ", $config->{author});

    $config->{email} ||= 'default {at} example.com';
    $config->{email} = $self->dialog("Your email: ", $config->{email});
}

1;
