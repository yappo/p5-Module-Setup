use t::Utils;
use Test::More tests => 9;

use Module::Setup::Flavor::Default;

do {
    my $config = +{
        plugins => [],
    };
    Module::Setup::Flavor::Default->setup_config('Module::Setup', $config);
    is_deeply $config->{plugins}, [];
};

do {
    my $config = +{
        plugins => ['VC::SVN'],
    };
    Module::Setup::Flavor::Default->setup_config('Module::Setup', $config);
    is_deeply $config->{plugins}, ['VC::SVN'];
};

do {
    my $config = +{
        plugins => [],
    };
    dialog {'y'};
    Module::Setup::Flavor::Default->setup_config('Module::Setup', $config);
    is_deeply $config->{plugins}, [qw/ VC::SVK VC::Git /];
};

do {
    my $config = +{
        plugins => [qw/ VC::SVN VC::SVK VC::Git /],
    };
    dialog {'y'};
    Module::Setup::Flavor::Default->setup_config('Module::Setup', $config);
    is_deeply $config->{plugins}, [qw/ VC::SVK VC::Git /];
};

do {
    my $config = +{
        plugins => [],
    };
    my @ans = qw( n y n );
    dialog { shift @ans };
    Module::Setup::Flavor::Default->setup_config('Module::Setup', $config);
    is_deeply $config->{plugins}, [qw/ VC::SVK /];
};

do {
    my $config = +{
        plugins => [qw/ VC::SVN /],
    };
    my @ans = qw( n n y );
    dialog { shift @ans };
    Module::Setup::Flavor::Default->setup_config('Module::Setup', $config);
    is_deeply $config->{plugins}, [qw/ VC::SVN VC::Git /];
};

do {
    my $config = +{
        plugins => [qw/ VC::SVN /, +{ module => 'VC::Git', config => +{ foo => 1 } }],
    };
    my @ans = qw( n n y );
    dialog { shift @ans };
    Module::Setup::Flavor::Default->setup_config('Module::Setup', $config);
    is_deeply $config->{plugins}, [qw/ VC::SVN /, +{ module => 'VC::Git', config => +{ foo => 1 } }];
};

do {
    my $config = +{
        plugins => [qw/ VC::SVN /, +{ module => 'VC::SVK', config => +{ foo => 1 } }],
    };
    my @ans = qw( n n y );
    dialog { shift @ans };
    Module::Setup::Flavor::Default->setup_config('Module::Setup', $config);
    is_deeply $config->{plugins}, [+{ module => 'VC::SVK', config => +{ foo => 1 } }, 'VC::Git'];
};

do {
    my $config = +{
        plugins => [+{ module => 'VC::SVN', config => +{ foo => 1 } }],
    };
    my @ans = qw( n y n );
    dialog { shift @ans };
    Module::Setup::Flavor::Default->setup_config('Module::Setup', $config);
    is_deeply $config->{plugins}, [qw/ VC::SVK /];
};
