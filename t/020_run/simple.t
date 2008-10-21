use t::Utils;
use Test::Base;
use YAML ();

plan tests => 6 * blocks;
filters { libs => ['yaml'], options => ['yaml'] };

default_dialog;

run {
    my $block = shift;

    my $argv = [ $block->module ];
    push @{ $argv }, $block->flavor if $block->flavor;
    my $add_options = $block->options || +{};
    module_setup { %{ $add_options }, target => 1 }, $argv;

    ok -d target_dir $block->create_dir;
    ok -d target_dir $block->create_dir, 't';
    ok -d target_dir $block->create_dir, 'xt';
    ok -d target_dir $block->create_dir, 'lib';

    my @path = @{ $block->libs };
    my $file = pop @path;
    ok -f target_dir($block->create_dir, 'lib', @path)->file($file);
    ok -f target_dir($block->create_dir)->file('Makefile.PL');

    clear_tempdir;
};

__END__

===
--- module: Foo
--- create_dir: Foo
--- libs
 - Foo.pm

===
--- module: Foo::Bar
--- create_dir: Foo-Bar
--- libs
 - Foo
 - Bar.pm

===
--- module: Foo::Bar::Baz_Bla
--- create_dir: Foo-Bar-Baz_Bla
--- libs
 - Foo
 - Bar
 - Baz_Bla.pm

===
--- module: Foo
--- flavor: flavor
--- create_dir: Foo
--- libs
 - Foo.pm

===
--- module: Foo
--- create_dir: Foo
--- libs
 - Foo.pm
--- options
  plugins:

===
--- module: Foo
--- create_dir: Foo
--- libs
 - Foo.pm
--- options
  plugins: []
