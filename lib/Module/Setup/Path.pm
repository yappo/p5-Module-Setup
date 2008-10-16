package Module::Setup::Path;
use strict;
use warnings;
use base 'Module::Setup::Path::Base';

use Path::Class;

use Module::Setup::Path::Config;
use Module::Setup::Path::Flavor;
use Module::Setup::Path::Flavors;
use Module::Setup::Path::Plugins;

sub new {
    my($class, @path) = @_;
    my $self = $class->SUPER::new(@path);

    $self->{flavor}         = undef;
    $self->{flavor_name}    = undef;
    $self->{flavors}        = Module::Setup::Path::Flavors->new($self->path_to('flavors'));
    $self->{global_plugins} = Module::Setup::Path::Plugins->new($self->path_to('plugins'));
    $self->{global_config}  = Module::Setup::Path::Config->new($self->path_to('config.yaml'));

    $self;
}

sub set_flavor {
    my($self, $flavor) = @_;
    $self->{flavor_name} = $flavor;
    $self->{flavor}      = Module::Setup::Path::Flavor->new($self->path_to('flavors', $flavor));
}

sub flavor         { shift->{flavor} }
sub flavors        { shift->{flavors} }
sub global_config  { shift->{global_config} }
sub global_plugins { shift->{global_plugins} }

sub is_initialized {
    my $self = shift;
    $self->is_dir && $self->global_plugins->is_dir;
}

sub init_directories {
    my $self = shift;
    $self->path->mkpath;
    $self->global_plugins->path->mkpath;
    $self->flavors->path->mkpath;
}

1;
