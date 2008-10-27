use Module::Setup::Test::Utils;
use Test::Base;

plan tests => 2 * blocks;

filters { input => [qw/lines chomp/], argv => [qw/lines chomp array/], options => 'yaml' };

run {
    my $block = shift;

    local @ARGV = $block->input;
    my $self = Module::Setup->new->setup_options;
    my $options = {
        target             => undef,
        plugins            => undef,
        direct             => undef,
        module_setup_dir   => undef,
        flavor_class       => undef,
        pack               => undef,
        flavor             => undef,
        init               => undef,
        additional         => undef,
        without_additional => undef,
        executable         => undef,
        devel              => undef,
        test               => undef,
        %{ $block->options || {} },
    };

    is_deeply $self->{argv}, $block->argv;
    is_deeply $self->{options}, $options;
};

__END__

===
--- input
Foo
--- argv
Foo
--- options

===
--- input
Foo default
--- argv
Foo default
--- options

===
--- input
--init
--- argv
--- options
init: 1

===
--- input
--init
--flavor-class=+Foo
--- argv
--- options
init: 1
flavor_class: +Foo

===
--- input
--init
--flavour-class=+Foo
--- argv
--- options
init: 1
flavor_class: +Foo

===
--- input
--flavor=flavor
Foo
--- argv
Foo
--- options
flavor: flavor

===
--- input
--flavour=flavor
Foo
--- argv
Foo
--- options
flavor: flavor

===
--- input
--additional=Add
--flavor-class=Flavor
Foo
--- argv
Foo
--- options
additional: Add
flavor_class: Flavor

===
--- input
--pack
--additional=Add
--- argv
--- options
pack: 1
additional: Add

===
--- input
--pack
--without-additional
--- argv
--- options
pack: 1
without_additional: 1

===
--- input
--devel
--test
--- argv
--- options
devel: 1
test: 1

===
--- input
--devel
--pack
--executable
--- argv
--- options
devel: 1
pack: 1
executable: 1

===
--- input
--pack
--executable
--- argv
--- options
pack: 1
executable: 1
