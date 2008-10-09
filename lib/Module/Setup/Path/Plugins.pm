package Module::Setup::Path::Plugins;
use strict;
use warnings;
use base 'Module::Setup::Path::Base';

use Module::Collect;

sub collect {
    my $self = shift;
    my $collect = Module::Collect->new( path => $self->path );
    return () unless $collect;
    @{ $collect->modules };
}

1;
