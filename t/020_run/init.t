use strict;
use warnings;
use Test::Base;
use File::Temp;
use Path::Class;
use YAML ();

use Module::Setup;

plan tests => 5 * blocks;

run {
    my $block = shift;

    local $ENV{MODULE_SETUP_DIR} = File::Temp->newdir;

    my $msetup = Module::Setup->new;

    my $options = {
        flavor_class => $block->flavor_class,
        init         => 1,
    };
    $msetup->run($options, [ $block->flavor ]);

    ok -d Path::Class::Dir->new( $ENV{MODULE_SETUP_DIR}, 'flavors', $block->create_dir );
    ok -d Path::Class::Dir->new( $ENV{MODULE_SETUP_DIR}, 'flavors', $block->create_dir, 'plugins' );
    ok -d Path::Class::Dir->new( $ENV{MODULE_SETUP_DIR}, 'flavors', $block->create_dir, 'template' );
    my $config = Path::Class::File->new( $ENV{MODULE_SETUP_DIR}, 'flavors', $block->create_dir, 'config.yaml' );
    ok -f $config;

    my $yaml = YAML::LoadFile($config);
    is ref($yaml), 'HASH';
}


__END__

===
--- flavor: 
--- flavor_class: 
--- create_dir: default

===
--- flavor: foo
--- flavor_class: 
--- create_dir: foo

===
--- flavor: default
--- flavor_class: Default
--- create_dir: default

===
--- flavor: cr
--- flavor_class: CodeRepos
--- create_dir: cr
