package Module::Setup::Plugin::VC::SVN;
use strict;
use warnings;
use base 'Module::Setup::Plugin';

use Module::Setup::Path::Dir;

sub register {
    my($self, ) = @_;
    $self->add_trigger( after_setup_module_attribute => \&after_setup_module_attribute );
}

sub after_setup_module_attribute {
    my $self = shift;
    if ($self->dialog("Subversion friendly? [Yn] ", 'y') =~ /[Yy]/) {
        $self->distribute->dist_path->subdir($_)->mkpath for (qw/ trunk tags branches /);
        $self->distribute->{dist_path} = Module::Setup::Path::Dir->new($self->distribute->dist_path, 'trunk');
        $self->plugins_stash->{'VC::SVN'} = +{
            is_subversion_friendly => 1,
        };
    }
}

1;
