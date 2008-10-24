use Module::Setup::Test::Utils;
use Test::More tests => 5;


do {
    module_setup { init => 1 };
    is Module::Setup::Test::Utils::context->select_flavor, 'default';
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
    my $selected;
    local *Module::Setup::log = sub {
        my($self, $msg) = @_;
        my $re = qr/You chose flavor: (one|two)/;
        like $msg, $re;
        $msg =~ $re;
        $selected = $1;
    };

    ok @ans;
    is Module::Setup::Test::Utils::context->select_flavor, $selected;
    ok !@ans;
};
