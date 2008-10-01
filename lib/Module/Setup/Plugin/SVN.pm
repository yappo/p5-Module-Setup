package Module::Setup::Plugin::SVN;
use strict;
use warnings;
use base 'Module::Setup::Plugin';

sub register {
    my($self, ) = @_;
    $self->add_trigger( after_setup_module_attribute => \&after_setup_module_attribute );
}

sub after_setup_module_attribute {
    my($self, $module_attribute) = @_;
    if ($self->dialog("Subversion friendly? [Yn] ", 'y') =~ /[Yy]/) {
        $self->create_directory( dir => File::Spec->catfile( $module_attribute->{dist_name}, $_) ) for (qw/ trunk tags branches /);
        push @{ $module_attribute->{dist_path} }, 'trunk';
    }
}

1;
