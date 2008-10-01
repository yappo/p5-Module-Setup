package Module::Setup::Flavor;
use strict;
use warnings;

use Carp ();
use YAML ();

sub load_data {
    my $class = shift;

    local $/;
    my $data = eval "package $class; <DATA>";
    Carp::croak "flavor template class is invalid: $class" unless $data;

    my @template = YAML::Load(join '', $data);
    @template;
}

1;
