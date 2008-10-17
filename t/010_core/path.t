use t::Utils;
use Test::More tests => 3;
use Module::Setup::Path;

do {
    my $obj = Module::Setup::Path->new(setup_dir 'foo');
    ok !$obj->is_initialized;
    $obj->path->mkpath;
    ok !$obj->is_initialized;
    $obj->global_plugins->path->mkpath;
    ok $obj->is_initialized;
};

1;
