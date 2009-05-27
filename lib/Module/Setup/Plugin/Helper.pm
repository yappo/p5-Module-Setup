package Module::Setup::Plugin::Helper;
use strict;
use warnings;
use base 'Module::Setup::Plugin';

use Module::Setup::Path::Dir;

sub register {
    my $self = shift;
    $self->add_trigger(
        after_setup_module_attribute => $self->can('setup_module_attribute')
    );
    $self->add_trigger(
        after_setup_template_vars    => $self->can('setup_template_vars')
    );
}

sub setup_module_attribute {
    my $setup = shift;
    if ($setup->{config}->{class}->is_append_files) {
        $setup->distribute->{dist_path} = Module::Setup::Path::Dir->new('.');
    }
}

sub setup_template_vars {
    my ($setup, $vars) = @_;

    my $conf = $setup->{helper} || {};
    my $flavor_class = $setup->{config}->{class};

    my $prefix = $flavor_class->helper_option_prefix;

    my %is_make_path = map { $_ => 1 } $flavor_class->generate_path_option_names;
    while (my($k, $v) = each %{ $conf }) {
        $vars->{"${prefix}_$k"} = $v;
        if ($is_make_path{$k}) {
            ($vars->{"${prefix}_${k}_path"} = $v) =~ s!::!/!g;
        }
    }

    if (ref($conf->{setup_template_vars_callback}) eq 'CODE') {
        $conf->{setup_template_vars_callback}->($setup, $vars);
    }
}


1;

=head1 NAME

Module::Setup::Plugin::Helper - L<Module::Setup::Helper> support plugin

=head1 SEE ALSO

L<Module::Setup::Helper>

=cut

