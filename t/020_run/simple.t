use strict;
use warnings;
use Test::Base;
use File::Temp;
use Path::Class;
use YAML ();

use Module::Setup;

plan tests => 6 * blocks;

my %dir_cache;
my $dir_count = 0;
run {
    my $block = shift;

    local $ENV{MODULE_SETUP_DIR} = $dir_cache{$dir_count++} = File::Temp->newdir;

    my $msetup = Module::Setup->new;

    my $target = $dir_cache{$dir_count++} = File::Temp->newdir;
    my $options = {
        target => $target,
    };

    no warnings 'redefine';
    *Module::Setup::dialog = sub {
        my($self, $msg, $default) = @_;
        return 'n' if $msg =~ /Check Makefile.PL\?/i;
        return 'n' if $msg =~ /Subversion friendly\?/i;
        return $default;
    };
    my $args = [ $block->module ];
    push @{ $args }, $block->flavor if $block->flavor;
    $msetup->run($options, $args);

    ok -d Path::Class::Dir->new( $target, $block->create_dir );
    ok -d Path::Class::Dir->new( $target, $block->create_dir, 't' );
    ok -d Path::Class::Dir->new( $target, $block->create_dir, 'xt' );
    ok -d Path::Class::Dir->new( $target, $block->create_dir, 'lib' );

    ok -f Path::Class::File->new( $target, $block->create_dir, 'lib', join('/',  @{ $block->libs }) );
    ok -f Path::Class::File->new( $target, $block->create_dir, 'Makefile.PL' );
}


__END__

===
--- module: Foo
--- create_dir: Foo
--- libs yaml
 - Foo.pm

===
--- module: Foo::Bar
--- create_dir: Foo-Bar
--- libs yaml
 - Foo
 - Bar.pm

===
--- module: Foo::Bar::Baz_Bla
--- create_dir: Foo-Bar-Baz_Bla
--- libs yaml
 - Foo
 - Bar
 - Baz_Bla.pm

===
--- module: Foo
--- flavor: flavor
--- create_dir: Foo
--- libs yaml
 - Foo.pm
