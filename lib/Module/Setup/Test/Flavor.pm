package Module::Setup::Test::Flavor;
use Module::Setup::Test::Utils;
use Carp ();
use File::Find::Rule;
use Test::More;

sub import {
    my $class  = shift;
    my $caller = caller;
    my %args   = @_;

    if ($args{for_test}) {
        no strict 'refs';
        no warnings 'redefine';
        *ok   = sub ($;$) { 1 };
        *like = sub ($$;$) { 1 };
        *plan = sub {};
    }

    for my $func (qw/ run_flavor_test name files file dirs options default_dialog dialog /) {
        no strict 'refs';
        *{"$caller\::$func"} = \&{ $func };
    }

    strict->import;
    warnings->import;
}

my $tests = {};
sub name ($) {
    $tests->{module} = shift;
}

sub files (@) {
    push @{ $tests->{files} }, @_;
}

sub file (@) {
    my $file = shift;
    push @{ $tests->{files} }, {
        file  => $file,
        likes => [ @_ ],
    };
}

sub dirs (@) {
    push @{ $tests->{dirs} }, @_;
}

sub options ($) {
    $tests->{options} = shift;
}


sub run_flavor_test (&) {
    my $code = shift;
    $tests = {
        module  => 'Default',
        files   => [],
        dirs    => [],
        options => {},
    };
    $code->();
    my $module  = delete $tests->{module};
    my $options = delete $tests->{options};
    $options->{target} = 1;

    # test count
    my $count =  2;
    $count += scalar(@{ $tests->{dirs} });
    for my $test (@{ $tests->{files} }) {
        $count++;
        if (ref($test) eq 'HASH') {
            $count += @{ $test->{likes} };
        }
    }
    
    plan tests => $count;
    module_setup $options, $module;

    my $base_path = context->distribute->dist_path;
    ok -d $base_path, 'base_path';

    my %files =  map { $_ => 1 } File::Find::Rule->new->relative->in( context->distribute->dist_path );

    for my $path (@{ $tests->{dirs} }) {
        Carp::croak "$path directory was missing" unless $files{$path};
        my $dir = $base_path->subdir( split '/', $path );
        ok -d $dir, "dir: $dir";
        delete $files{$path};
    }

    for my $data (@{ $tests->{files} }) {
        my $likes = [];
        my $path  = $data;
        if (ref($data) eq 'HASH') {
            $path  = $data->{file};
            $likes = $data->{likes};
        }
        Carp::croak "$path file was missing" unless $files{$path};
        my $file = $base_path->file( split '/', $path );
        ok -f $file, "file: $file";

        if (@{ $likes }) {
            my $slurp = $file->slurp;
            for my $re (@{ $likes }) {
                like $slurp, $re, "like $re";
            }
        }

        delete $files{$path};
    }

    my $is_ok = !scalar(keys %files);
    ok $is_ok, "is all ok";
    unless ($is_ok) {
        my $files = join ', ', keys %files;
        Carp::croak "missing tests for $files";
    }

    return 1;
}


1;

=head1 NAME

Module::Setup::Test::Flavor - Test for flavor

=cut


