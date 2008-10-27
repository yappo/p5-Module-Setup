use Module::Setup::Test::Utils;
use Test::More tests => 2;

do {
    my $obj = Module::Setup->new(argv => ['', ''], options => { module_setup_dir => setup_dir } );
    eval { $obj->run };
    like $@, qr/module name is required/;
};

do {
    my $obj = Module::Setup->new( argv => ['Foo', ''], options => { module_setup_dir => setup_dir } );
    no warnings 'redefine';
    local *Module::Setup::select_flavor = sub {};
    eval { $obj->run };
    like $@, qr/flavor name is required/;
};
