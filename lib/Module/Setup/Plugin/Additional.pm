package Module::Setup::Plugin::Additional;
use strict;
use warnings;
use base 'Module::Setup::Plugin';

use Module::Setup::Path::Template;

sub register {
    my($self, ) = @_;
    $self->add_trigger( append_template_file => \&append_template_file );
}

sub append_template_file {
    my $self = shift;

    my $config = $self->base_dir->flavor->additional->config->load;
    for my $additional ( $self->base_dir->flavor->additional->path->children ) {
        next unless $additional->is_dir;
        my $name = $additional->dir_list(-1);
        return unless $self->dialog("Do you install additional template by $name? [yN] ", 'n') =~ /[Yy]/;

        my $base_src = Module::Setup::Path::Template->new($self->base_dir->flavor->additional->path, $name);
        for my $path ($base_src->find_files) {
            $self->distribute->install_template($self, $path, $base_src);
        }
        push @{ $self->distribute->{additionals} }, $config->{$name};
    }
}

1;
