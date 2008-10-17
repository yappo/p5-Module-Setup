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

    !$self->system('perl', 'Makefile.PL') or die $?;
    !$self->system('make', 'test')        or die $?;
    !$self->system('make', 'manifest')    or die $?;
    !$self->system('make', 'distclean')   or die $?;
}

1;
