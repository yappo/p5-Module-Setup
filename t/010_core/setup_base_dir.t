use Module::Setup::Test::Utils;
use Test::More tests => 7;

my $obj = Module::Setup->new;

do {
    no warnings 'redefine';
    local *File::HomeDir::my_home = sub { setup_dir };
    $obj->setup_base_dir;
    is $obj->base_dir->path, setup_dir('.module-setup');
    ok -d setup_dir('.module-setup');
};

do {
    local $ENV{MODULE_SETUP_DIR} = setup_dir('env');
    $obj->setup_base_dir;
    is $obj->base_dir->path, setup_dir('env');
    ok -d setup_dir('env');
};

do {
    local $obj->{options}->{module_setup_dir} = setup_dir('options');
    $obj->setup_base_dir;
    is $obj->base_dir->path, setup_dir('options');
    ok -d setup_dir('options');
};

do {
    no warnings 'redefine';
    local *Path::Class::Dir::new = sub {};
    eval { $obj->setup_base_dir };
    like $@, qr/module_setup directory was not able to be discovered/;
};
