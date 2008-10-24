use Module::Setup::Test::Flavor for_test => 1;
use Test::More tests => 5;

do {
    local $@;
    eval { 
        run_flavor_test {
            default_dialog;
            name 'MyApp';
            files qw( .shipit Changes MANIFEST.SKIP README xt/01_podspell.t xt/02_perlcritic.t xt/03_pod.t xt/perlcriticrc );
            file 'Makefile.PL'  => qr!lib/MyApp.pm!;
            file 'lib/MyApp.pm' => qr/package MyApp;/;
            file 't/00_compile.t'  => qr!use_ok 'MyApp'!;
            dirs qw( lib t xt );
            options +{};
        };
    };
    ok !$@;
};

do {
    local $@;
    eval { run_flavor_test { files qw( DUMMY ) } };
    like $@, qr/DUMMY file was missing/;
};

do {
    local $@;
    eval { run_flavor_test { dirs qw( DUMMY ) } };
    like $@, qr/DUMMY directory was missing/;
};

do {
    local $@;
    eval { 
        run_flavor_test {
            default_dialog;
            name 'MyApp';
            files qw( .shipit Changes MANIFEST.SKIP README xt/01_podspell.t xt/02_perlcritic.t xt/03_pod.t xt/perlcriticrc );
            file 'Makefile.PL'  => qr!lib/MyApp.pm!;
            file 'lib/MyApp.pm' => qr/package MyApp;/;
            file 't/00_compile.t'  => qr!use_ok 'MyApp'!;
            dirs qw( lib t );
        };
    };
    like $@, qr/missing tests for xt/;
};

do {
    local $@;
    eval { 
        run_flavor_test {
            default_dialog;
            name 'MyApp';
            files qw( .shipit Changes MANIFEST.SKIP xt/01_podspell.t xt/02_perlcritic.t xt/03_pod.t xt/perlcriticrc );
            file 'Makefile.PL'  => qr!lib/MyApp.pm!;
            file 'lib/MyApp.pm' => qr/package MyApp;/;
            file 't/00_compile.t'  => qr!use_ok 'MyApp'!;
            dirs qw( lib t xt );
        };
    };
    like $@, qr/missing tests for README/;
};
