package Module::Setup::Plugin;
use strict;
use warnings;

use Scalar::Util qw(weaken);

sub new {
    my($class, %args) = @_;
    my $self = bless { %args }, $class;
    weaken $self->{context};
    $self->register;
    $self;
}

sub register {}

sub add_trigger {
    my($self, @args) = @_;
    $self->{context}->add_trigger(@args);
}

1;
