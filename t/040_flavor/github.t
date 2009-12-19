use Module::Setup::Test::Flavor;

run_flavor_test {
    flavor 'GitHub';
    dialog { 'n' };
    name 'MyApp';
    files qw( .shipit Changes MANIFEST.SKIP README xt/01_podspell.t xt/02_perlcritic.t xt/03_pod.t xt/perlcriticrc );
    file 'Makefile.PL'  => qr!lib/MyApp.pm!;
    file 'lib/MyApp.pm' => qr/package MyApp;/, qr/MyApp is/;
    file 't/00_compile.t'  => qr!use_ok 'MyApp'!;
    file '.gitignore'  => qr/MANIFEST.bak/;
    dirs qw( lib t xt );
};
