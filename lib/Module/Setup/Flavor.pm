package Module::Setup::Flavor;
use strict;
use warnings;

use Carp ();
use YAML ();

my %data_cache;
sub loader {
    my $class = shift;

    unless ($data_cache{$class}) {
        local $/;
        my $data = eval "package $class; <DATA>"; ## no critic
        Carp::croak "flavor template class is invalid: $class" unless $data;

        my @template = YAML::Load(join '', $data);
        if (scalar(@template) == 1 && !defined $template[0]) {
            $data_cache{$class} = [];
        } else {
            $data_cache{$class} = \@template;
        }
    };
    @{ $data_cache{$class} };
}

sub import_template {
    my($class, $base_class) = @_;

    eval "require $base_class"; ## no critic
    Carp::croak $@ if $@;

    my @base_template  = $base_class->loader;
    my @local_template = loader($class);

    my %template_index;
    my $template_config;
    my $anthor_key_count = 0;
 LOOP:
    for my $tmpl (@local_template) {
        if (exists $tmpl->{config}) {
            $template_config = $tmpl;
            next;
        }
        for my $type (qw/ file plugin dir /) {
            next unless exists $tmpl->{$type};
            $template_index{"$type - $tmpl->{$type}"} = $tmpl;
            next LOOP;
        }
        $template_index{'anthor - ' . $anthor_key_count++} = $tmpl;
    }

    my @template;
 LOOP:
    for my $tmpl (@base_template) {
        if (exists $tmpl->{config}) {
            $template_config = $tmpl unless defined $template_config;
            next;
        }
        for my $type (qw/ file plugin dir /) {
            next unless exists $tmpl->{$type};
            my $template = delete $template_index{"$type - $tmpl->{$type}"};
            $template = $tmpl unless $template;
            push @template, $template;
            next LOOP;
        }
        push @template, $tmpl;
    }

    for my $tmpl (values %template_index) {
        push @template, $tmpl;
    }
    push @template, $template_config if $template_config;

    @template;
}

sub setup_config {
    my($class, $context, $config) = @_;
}

sub setup_additional {
    my($class, $context, $config) = @_;
}


1;

=head1 NAME

Module::Setup::Flavor - Module::Setup Flavor

=cut

__DATA__
