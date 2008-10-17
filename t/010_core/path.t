use t::Utils;
use Test::More tests => 5;
use Module::Setup::Path;

do {
    my $obj = Module::Setup::Path->new(setup_dir 'foo');
    ok !$obj->is_initialized;
    $obj->path->mkpath;
    ok !$obj->is_initialized;
    $obj->global_plugins->path->mkpath;
    ok $obj->is_initialized;

    ok !$obj->global_config->is_file;
    $obj->global_config->dump({ foo => 1 });
    ok $obj->global_config->is_file;
};

1;
