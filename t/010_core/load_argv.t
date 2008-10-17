use t::Utils;
use Test::More tests => 6;

my $obj = Module::Setup->new(
    options => {
    },
    argv    => [qw/one two/],
);

is $obj->_load_argv( one => '1'), 'one';
is $obj->_load_argv( two => '2'), 'two';
is $obj->_load_argv( one => '3'), 3;
is $obj->_load_argv( two => '4'), 4;
is $obj->_load_argv( undef => undef), undef;
is_deeply $obj->{options}, +{
    one   => 3,
    two   => 4,
    undef => undef,
};
