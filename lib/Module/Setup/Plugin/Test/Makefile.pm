package Module::Setup::Plugin::Test::Makefile;
use strict;
use warnings;
use base 'Module::Setup::Plugin';

sub register {
    my($self, ) = @_;
    $self->add_trigger( check_skeleton_directory => \&check_skeleton_directory );
}

sub check_skeleton_directory {
    my $self = shift;
    return unless $self->dialog("Check Makefile.PL? [Yn] ", 'y') =~ /[Yy]/;

    !system "perl Makefile.PL" or die $?;
    !system 'make test'        or die $?;
    !system 'make manifest'    or die $?;
    !system 'make distclean'   or die $?;
}

1;
