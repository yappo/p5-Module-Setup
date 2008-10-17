use t::Utils;
use Test::More tests => 16;
use Module::Setup::Flavor;

use t::Flavor::FlavorTest;
use t::Flavor::FlavorTest2;

do {
    local $@;
    eval { Module::Setup::Flavor->loader };
    like $@, qr/flavor template class is invalid: Module::Setup::Flavor/;
    eval { Module::Setup::Flavor->import_template( 'Module::Setup::Flavor::DUMMY' ) };
    like $@, qr!Can't locate Module/Setup/Flavor/DUMMY.pm!;
};

do {
    my @template = t::Flavor::FlavorTest->import_template( 't::Flavor::FlavorTestBase' );

    is scalar(@template), 9;

    ok grep { exists $_->{file} && $_->{file} eq 'foo.txt' } @template;
    ok grep { exists $_->{file} && $_->{file} eq 'bar.txt' } @template;
    ok grep { exists $_->{plugin} && $_->{plugin} eq 'foo.pm' } @template;
    ok grep { exists $_->{plugin} && $_->{plugin} eq 'bar.pm' } @template;
    ok grep { exists $_->{config} && $_->{config}->{foo} } grep { $_->{config} } @template;

    # template check
    for (grep { exists $_->{file} && $_->{file} eq 'foo.txt' } @template) {
        like $_->{template}, qr/local/;
    }
    for (grep { exists $_->{file} && $_->{file} eq 'bar.txt' } @template) {
        like $_->{template}, qr/base/;
    }
    for (grep { exists $_->{plugin} && $_->{plugin} eq 'foo.pm' } @template) {
        like $_->{template}, qr/package local::foo;/;
    }
    for (grep { exists $_->{plugin} && $_->{plugin} eq 'bar.pm' } @template) {
        like $_->{template}, qr/package base::bar;/;
    }

    ok grep { exists $_->{foo} && $_->{foo} } @template;
    ok grep { exists $_->{bar} && $_->{bar} } @template;
};

do {
    my @template = t::Flavor::FlavorTest2->import_template( 't::Flavor::FlavorTest2Base' );
    is scalar(@template), 1;
    ok grep { exists $_->{file} && $_->{file} eq 'foo.txt' } @template;
};
