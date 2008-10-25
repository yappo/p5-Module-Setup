package Module::Setup::Path::Flavor;
use strict;
use warnings;
use base 'Module::Setup::Path::Base';

use YAML ();

use Module::Setup::Path::Config;
use Module::Setup::Path::Plugins;
use Module::Setup::Path::Template;
use Module::Setup::Path::Additional;

sub new {
    my($class, @path) = @_;
    my $self = $class->SUPER::new(@path);

    $self->{config}     = Module::Setup::Path::Config->new($self->path_to('config.yaml'));
    $self->{plugins}    = Module::Setup::Path::Plugins->new($self->path_to('plugins'));
    $self->{template}   = Module::Setup::Path::Template->new($self->path_to('template'));
    $self->{additional} = Module::Setup::Path::Additional->new($self->path_to('additional'));

    $self;
}

sub config   { shift->{config} }
sub plugins  { shift->{plugins} }
sub template { shift->{template} }
sub additional { shift->{additional} }

sub create_flavor {
    my($self, $config) = @_;

    $self->path->mkpath;
    $self->plugins->path->mkpath;
    $self->template->path->mkpath;
    $self->additional->path->mkpath;
    YAML::DumpFile($self->config->path, $config);
}

1;
