use t::Utils;
use Test::More tests => 2;

do {
    my $obj = Module::Setup->new( argv => ['', '']);
    eval { $obj->run };
    like $@, qr/module name is required/;
};

do {
    my $obj = Module::Setup->new( argv => ['', '']);
    no warnings 'redefine';
    local *Module::Setup::select_flavor = sub {};
    eval { $obj->run };
    like $@, qr/flavor name is required/;
};
