package Module::Setup::Path::File;
use strict;
use warnings;
use base 'Path::Class::File';

sub stringify {
    my($self) = @_;
    return $self->{__stringify_cache} ||= $self->SUPER::stringify;
}

1;
