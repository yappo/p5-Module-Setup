use t::Utils;
use Test::Base;
use YAML ();

plan tests => 6 * blocks;

run {
    my $block = shift;

    module_setup { flavor_class => $block->flavor_class, init => 1 }, $block->flavor;

    ok -d flavors_dir  $block->create_dir;
    ok -d plugins_dir  $block->create_dir;
    ok -d template_dir $block->create_dir;
    ok -d additional_dir $block->create_dir;
    ok -f config_file  $block->create_dir;

    my $yaml = YAML::LoadFile(config_file  $block->create_dir);
    is ref($yaml), 'HASH';

    clear_tempdir;
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
