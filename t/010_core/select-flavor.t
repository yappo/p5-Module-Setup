use t::Utils;
use Test::More tests => 5;


do {
    module_setup { init => 1 };
    is t::Utils::context->select_flavor, 'default';
    clear_tempdir;
};

do {
    module_setup { init => 1 };
    module_setup { init => 1 }, 'one';
    module_setup { init => 1 }, 'two';
    my $fh = setup_dir('flavors')->file('dummy')->openw;
    print $fh 'file';
    close $fh;

    my @ans = qw( x z s 4 2 );
    no warnings 'redefine';
    local $Module::Setup::HAS_TERM = 1;
    local *Module::Setup::prompt = sub ($;$) {
        my($msg, $default) = @_;
        shift @ans;
    };
    local *Module::Setup::log = sub {
        my($self, $msg) = @_;
        like $msg, qr/You chose flavor: one/;
    };

    ok @ans;
    is t::Utils::context->select_flavor, 'one';
    ok !@ans;
};
