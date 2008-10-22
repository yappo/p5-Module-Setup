package t::Flavor::Null;
use base 'Module::Setup::Flavor';

sub loader {
    (
        {
            file => undef,
        },
        {
            dir => undef,
        },
        {
            plugin => undef,
        },
        {
            config => undef,
        },
        {
            foo => 'bar',
        },
    );
}

1;
