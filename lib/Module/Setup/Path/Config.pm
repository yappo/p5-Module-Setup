package Module::Setup::Path::Config;
use strict;
use warnings;
use base 'Module::Setup::Path::Base';

use YAML ();

use Module::Setup;
use Module::Setup::Path::File;

sub new {
    my($class, @path) = @_;
    my $self = $class->SUPER::new(@path);
    $self->{path} = Module::Setup::Path::File->new(@path);
    $self;
}

sub dump {
    my($self, $config) = @_;
    Module::Setup::log($self, "Dump config " . $self->path);
    YAML::DumpFile($self->path, $config);
}

sub load {
    my $self = shift;
    YAML::LoadFile( $self->path );
}

1;
