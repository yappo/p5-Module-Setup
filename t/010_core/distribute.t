package Context;
use t::Utils;

sub call_trigger {}
sub write_file {}

use t::Utils;
use Test::More tests => 5;
use Module::Setup::Distribute;
use Module::Setup::Path::Dir;
use Module::Setup::Path::File;

do {
    my $obj = Module::Setup::Distribute->new('Foo::Bar');
    is $obj->dist_path, Module::Setup::Path::Dir->new('.', 'Foo-Bar');
    is_deeply $obj->package, [qw/ Foo Bar /];
};

do {
    my $obj = Module::Setup::Distribute->new('Foo::Bar', target => undef);
    is $obj->dist_path, Module::Setup::Path::Dir->new('.', 'Foo-Bar');
    is_deeply $obj->package, [qw/ Foo Bar /];
};

do {
    my $obj = Module::Setup::Distribute->new('Foo::Bar', target => target_dir);
    my $options = +{
        dist_path => Module::Setup::Path::File->new(qw/ ____var-foo-var____ ____var-bar-var____.txt /),
        template  => undef,
        vars      => +{
            foo    => 'FOO',
            config => +{
                bar => 'BAR',
            },
        },
        content   => undef,
    };
    $obj->write_template('Context', $options);
    is $obj->install_files->[0], Module::Setup::Path::File->new('FOO', 'BAR.txt');
};

1;
