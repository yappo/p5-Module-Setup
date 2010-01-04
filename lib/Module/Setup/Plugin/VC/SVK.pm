package Module::Setup::Plugin::VC::SVK;
use strict;
use warnings;
use base 'Module::Setup::Plugin::VC::SVN';

sub register {
    my($self, ) = @_;
    $self->add_trigger( before_dump_config => \&before_dump_config );
    $self->add_trigger( after_setup_module_attribute => sub { shift->SUPER::after_setup_module_attribute(@_) } );
    $self->add_trigger( finish_of_run => \&finish_of_run );
}

sub before_dump_config {
    my($self, $config) = @_;

    $config->{plugin_vc_svk_scratch_repos} ||= '//scratch';
    $config->{plugin_vc_svk_scratch_repos} =
        $self->dialog("Your svk base scratch DEPOTPATH: ", $config->{plugin_vc_svk_scratch_repos});
}

sub finish_of_run {
    my $self = shift;
    return unless $self->dialog("import to SVK scratch DEPOTPATH? [yN] ", 'n') =~ /[Yy]/;

    !$self->system(
        'svk', 'import',
        '-m', $self->distribute->dist_name . ' import',
        $self->config->{plugin_vc_svk_scratch_repos} . '/' . $self->distribute->dist_name,
        '--from-checkout', $self->distribute->base_path,
    ) or die $?;

    $self->distribute->base_path->rmtree;

    my $trunk_path = $self->plugins_stash->{'VC::SVN'}->{is_subversion_friendly} ? '/trunk' : '';
    !$self->system(
        'svk', 'co',
        $self->config->{plugin_vc_svk_scratch_repos} . '/' . $self->distribute->dist_name . $trunk_path,
        $self->distribute->dist_name,
    ) or die $?;
}

1;
