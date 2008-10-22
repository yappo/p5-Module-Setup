package t::Utils;
use strict;
use warnings;

use File::Temp;
use Path::Class;

use Module::Setup;

my $stdout = [];
sub stdout { $stdout }

sub import {
    my $class  = shift;
    my $caller = caller;
    my %args   = @_;

    for my $func (qw/ module_setup stdout dialog default_dialog setup_dir target_dir clear_tempdir flavors_dir template_dir additional_dir additional_config_file plugins_dir config_file /) {
        no strict 'refs';
        *{"$caller\::$func"} = \&{ $func };
    }

    strict->import;
    warnings->import;

    unless ($args{without_stdout}) {
        no warnings 'redefine';
        *Module::Setup::stdout = sub { push @{ $stdout }, $_[1] };
    }
}

sub _path_dir (@) {
    Path::Class::Dir->new(@_);
}
my $setup_dir;
sub setup_dir (@) {
    $setup_dir ||= File::Temp->newdir;
    _path_dir($setup_dir, @_);
}
sub flavors_dir {
    setup_dir('flavors', @_);
}
sub template_dir {
    my $flavor = shift;
    flavors_dir($flavor, 'template', @_);
}
sub additional_dir {
    my $flavor = shift;
    flavors_dir($flavor, 'additional', @_);
}
sub additional_config_file {
    my $flavor = shift;
    additional_dir($flavor)->file('config.yaml');
}
sub plugins_dir {
    my $flavor = shift;
    flavors_dir($flavor, 'plugins', @_);
}
sub config_file {
    my $flavor = shift;
    flavors_dir($flavor)->file('config.yaml');
}

my $target_dir;
sub target_dir (@) {
    $target_dir ||= File::Temp->newdir;
    _path_dir($target_dir, @_);
}

sub clear_tempdir {
    $setup_dir  = undef;
    $target_dir = undef;
}

my $context;
sub context { $context }
sub module_setup ($@) {
    $stdout = [];
    my($options, @argv) = @_;
    @argv = @{ $argv[0] } if ref $argv[0] eq 'ARRAY';

    $options->{module_setup_dir} ||= setup_dir;
    if ($options->{target}) {
        $options->{target} = target_dir;
    }

    $context = Module::Setup->new(
        options => $options,
        argv => \@argv,
    );
    $context->run;
}

sub dialog (;&) {
    my $code = shift;
    if (ref $code eq 'CODE') {
        no warnings 'redefine';
        *Module::Setup::dialog = $code;
    }
}

sub default_dialog {
    dialog {
        my($self, $msg, $default) = @_;
        return 'n' if $msg =~ /Check Makefile.PL\?/i;
        return 'n' if $msg =~ /Subversion friendly\?/i;
        return $default;
    };
}


1;
