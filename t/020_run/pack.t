use t::Utils;
use Test::Base;
use YAML ();

plan tests => 3 * blocks;

run {
    my $block = shift;

    my $options = { init => 1 };
    $options->{flavor_class} = $block->flavor_class if $block->flavor_class;
    module_setup $options;

    module_setup { pack => 1 }, $block->argv;

    like stdout->[0], qr/@{[ $block->regexp_1 ]}/;
    like stdout->[0], qr/@{[ $block->regexp_2 ]}/;
    like stdout->[0], qr/@{[ $block->regexp_3 ]}/;

    clear_tempdir;
};

__END__

===
--- argv yaml
- MyTest::Flavor
--- regexp_1: package MyTest::Flavor;
--- regexp_2: Makefile.PL
--- regexp_3: lib

===
--- argv yaml
- Foo::Bar::Flavor
--- regexp_1: package Foo::Bar::Flavor;
--- regexp_2: Makefile.PL
--- regexp_3: lib/____var-module_path-var____.pm

===
--- argv yaml
- Flavor
--- regexp_1: package Flavor;
--- regexp_2: Makefile.PL
--- regexp_3: lib


===
--- flavor_class: CodeRepos
--- argv yaml
- CR::Flavor
- default
--- regexp_1: package CR::Flavor;
--- regexp_2: svn
--- regexp_3: coderepos
