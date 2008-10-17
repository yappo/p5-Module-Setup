use t::Utils;
use Test::More tests => 4;

no warnings 'redefine';
do {
    local *Module::Setup::_setup_options_pod2usage = sub { ok 1 };
    local @ARGV = qw( --help );
    Module::Setup->new->setup_options;
};

do {
    local *Module::Setup::_setup_options_pod2usage = sub { ok 1 };
    local @ARGV = qw( --helo );
    Module::Setup->new->setup_options;
};

do {
    local *Module::Setup::_setup_options_pod2usage = sub { ok 1 };
    local @ARGV;
    Module::Setup->new->setup_options;
};

do {
    local *Module::Setup::_setup_options_version = sub { ok 1 };
    local @ARGV = qw( --version );;
    Module::Setup->new->setup_options;
};
