package Module::Setup::Path::Additional;
use strict;
use warnings;
use base 'Module::Setup::Path::Base';

use Module::Setup::Path::Config;

sub new {
    my($class, @path) = @_;
    my $self = $class->SUPER::new(@path);

    $self->{config} = Module::Setup::Path::Config->new($self->path_to('config.yaml'));

    $self;
}

sub config   { shift->{config} }

1;
