package t::Flavor::Null;

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
