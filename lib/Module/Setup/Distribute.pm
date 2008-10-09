package Module::Setup::Distribute;
use strict;
use warnings;

use Fcntl qw( :mode );

use Module::Setup::Path::Dir;

sub new {
    my($class, $module, %args) = @_;

    my @pkg    = split /::/, $module;
    my $target = exists $args{target} && $args{target} ? $args{target} : '.';

    my $self = bless {
        module        => $module,
        package       => \@pkg,
        dist_name     => join('-', @pkg),
        install_files => [],
    }, $class;

    $self->{base_path}   = Module::Setup::Path::Dir->new($target, $self->{dist_name});
    $self->{dist_path}   = Module::Setup::Path::Dir->new($target, $self->{dist_name});
    $self->{module_path} = join '/', @{ $self->{package} };

    $self;
}

sub module        { shift->{module} };
sub module_path   { shift->{module_path} };
sub package       { shift->{package} };
sub dist_name     { shift->{dist_name} };
sub dist_path     { shift->{dist_path} };
sub template_vars { shift->{template_vars} };

sub set_template_vars {
    my($self, $vars) = @_;
    $self->{template_vars} = $vars;
}

sub install_template {
    my($self, $context, $path) = @_;

    my $src      = $context->base_dir->flavor->template->path_to($path);
    my $template = $src->slurp;
    my $options = +{
        dist_path => $self->dist_path->file($path),
        template  => $template,
        chmod     => sprintf('%03o', S_IMODE(( stat $src )[2])),
        vars      => $self->template_vars,
        content   => undef,
    };
    $self->write_template($context, $options);
}

sub write_template {
    my($self, $context, $options) = @_;
    my $is_dir = $options->{dist_path}->is_dir;

    $context->call_trigger( template_process => $options );
    $options->{template} = delete $options->{content} unless $options->{template};
    $options->{dist_path} =~ s/____var-(.+)-var____/$options->{vars}->{$1} || $options->{vars}->{config}->{$1}/eg;

    if ($is_dir) {
        $options->{dist_path} = Module::Setup::Path::Dir->new($options->{dist_path});
    } else {
        $options->{dist_path} = Module::Setup::Path::File->new($options->{dist_path});
    }

    push @{ $self->{install_files} }, $options->{dist_path};
    $context->write_file($options);
}

1;
