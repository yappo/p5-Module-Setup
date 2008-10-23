use t::Utils;
use Test::More tests => 24;
use Module::Setup::Flavor;

use t::Flavor::FlavorTest;
use t::Flavor::FlavorTest2;
use t::Flavor::FlavorTestDouble;

do {
    local $@;
    eval { Module::Setup::Flavor->new->loader };
    like $@, qr/flavor template class is invalid: Module::Setup::Flavor/;
    eval { t::Flavor::FlavorTest->new->import_template( 'Module::Setup::Flavor::DUMMY' ) };
    like $@, qr!Can't locate Module/Setup/Flavor/DUMMY.pm!;
};

do {
    my @template = t::Flavor::FlavorTest->new->import_template( 't::Flavor::FlavorTestBase' );

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
    my @template = t::Flavor::FlavorTest2->new->import_template( 't::Flavor::FlavorTest2Base' );
    is scalar(@template), 1;
    ok grep { exists $_->{file} && $_->{file} eq 'foo.txt' } @template;
};

do {
    my @template = t::Flavor::FlavorTestDouble->new->import_template( 't::Flavor::FlavorTestBase', 't::Flavor::FlavorTestBase2' );

    is scalar(@template), 10;
    ok !grep { exists $_->{config} && $_->{config}->{foo} } grep { $_->{config} } @template;
    ok grep { exists $_->{config} && $_->{config}->{base2} } grep { $_->{config} } @template;

    ok grep { exists $_->{file} && $_->{file} eq 'foo.txt' } @template;
    ok grep { exists $_->{file} && $_->{file} eq 'double.txt' } @template;
    ok grep { exists $_->{file} && $_->{file} eq 'base2.txt' } @template;

    for (grep { exists $_->{file} && $_->{file} eq 'foo.txt' } @template) {
        like $_->{template}, qr/base2/;
    }
    for (grep { exists $_->{file} && $_->{file} eq 'base2.txt' } @template) {
        like $_->{template}, qr/nya-mo/;
    }
    for (grep { exists $_->{file} && $_->{file} eq 'double' } @template) {
        like $_->{template}, qr/2/;
    }

};
