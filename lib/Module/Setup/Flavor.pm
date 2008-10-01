package Module::Setup::Flavor;
use strict;
use warnings;

use Carp ();
use YAML ();

sub loader {
    my $class = shift;

    local $/;
    my $data = eval "package $class; <DATA>";
    Carp::croak "flavor template class is invalid: $class" unless $data;

    my @template = YAML::Load(join '', $data);
    @template;
}

sub import_template {
    my($class, $base_class) = @_;

    eval "require $base_class";
    Carp::croak $@ if $@;

    my @base_template  = $base_class->loader;
    my @local_template = loader($class);

    my %template_index;
    my $template_config;
    for my $tmpl (@local_template) {
        if (exists $tmpl->{file}) {
            $template_index{'template - '.$tmpl->{file}} = $tmpl;
        } elsif (exists $tmpl->{plugin}) {
            $template_index{'plugins - '.$tmpl->{plugin}} = $tmpl;
        } elsif (exists $tmpl->{config}) {
            $template_config = $tmpl;
        }
    }

    my @template;
    for my $tmpl (@base_template) {
        if (exists $tmpl->{file}) {
            push @template, (delete $template_index{'template - ' . $tmpl->{file}} || $tmpl);
        } elsif (exists $tmpl->{plugin}) {
            push @template, (delete $template_index{'plugins - ' . $tmpl->{plugin}} || $tmpl);
        } elsif (exists $tmpl->{config} && !defined $template_config) {
            $template_config = $tmpl;
        }
    }

    for my $tmpl (values %template_index) {
        push @template, $tmpl;
    }
    push @template, $template_config if $template_config;

    @template;
}

1;
