use Module::Setup::Test::Utils;
use Test::Base;
use YAML ();

plan tests => 9 * blocks;

run {
    my $block = shift;

    module_setup { flavor_class => $block->flavor_class, init => 1 }, $block->flavor;

    ok -d flavors_dir  $block->create_dir;
    ok -d plugins_dir  $block->create_dir;
    ok -d template_dir $block->create_dir;
    ok -d additional_dir $block->create_dir;
    ok -f additional_config_file $block->create_dir;
    is ref(YAML::LoadFile(additional_config_file($block->create_dir))), 'HASH';
    ok -f config_file  $block->create_dir;

    my $config = YAML::LoadFile(config_file $block->create_dir);
    is ref($config), 'HASH';

    my $flavor_class = $block->flavor_class || 'Default';
    $flavor_class = "Module::Setup::Flavor::$flavor_class" unless $flavor_class =~ s/^\+//;
    is $config->{class}, $flavor_class;

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
