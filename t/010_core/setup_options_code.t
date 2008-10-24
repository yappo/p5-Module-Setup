BEGIN {
    *CORE::GLOBAL::exit = sub {};
}
use Module::Setup::Test::Utils;
use Test::More tests => 5;
use IO::Scalar;

sub run_setup (@) {
    my $out_re = shift;
    my $err_re = shift;

    local @ARGV = @_;
    my $out;
    my $err;
    tie *STDOUT, 'IO::Scalar', \$out;
    tie *STDERR, 'IO::Scalar', \$err;
    Module::Setup->new->setup_options;
    untie *STDOUT;
    untie *STDERR;

    like $out, $out_re if $out_re;
    like $err, $err_re if $err_re;
}


run_setup qr/test synopsis/;
run_setup qr/test synopsis/, undef, qw( --help );
run_setup qr/test synopsis/, qr/Unknown option: hello/, qw( --hello );
run_setup qr/module-setup v/, undef, qw( --version );


__END__

=head1 NAME

Test - Pod

=head1 SYNOPSIS

test synopsis

=cut

