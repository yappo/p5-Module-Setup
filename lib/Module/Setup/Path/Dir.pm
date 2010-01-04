package Module::Setup::Path::Dir;
use strict;
use warnings;
use base 'Path::Class::Dir';

use Module::Setup;

sub stringify {
    my($self) = @_;
    return $self->{__stringify_cache} ||= $self->SUPER::stringify;
}

sub mkpath {
    my $self  = shift;
    Module::Setup::log($self, "Creating directory $self");
    $self->Path::Class::Dir::mkpath(@_);
}
1;
