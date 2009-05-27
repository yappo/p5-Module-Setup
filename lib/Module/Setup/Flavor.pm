package Module::Setup::Flavor;
use strict;
use warnings;

use Carp ();
use Storable ();
use YAML ();

sub new { bless {}, shift }

my %data_cache;
sub loader {
    my $self = shift;
    my $class = ref($self);
    $class = $self unless $class;

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
    @{ Storable::dclone($data_cache{$class}) };
}

sub _import_template {
    my($self, $base_class, $args) = @_;

    eval "require $base_class"; ## no critic
    Carp::croak $@ if $@;

    my @base_template  = $base_class->loader;
    my @template;
 LOOP:
    for my $tmpl (@base_template) {
        if (exists $tmpl->{config}) {
            $args->{template_config} = $tmpl unless $args->{template_config};
            next;
        }
        for my $type (qw/ file plugin dir /) {
            next unless exists $tmpl->{$type};
            my $key = "$type - $tmpl->{$type}";
            next LOOP if $args->{template_loaded}->{$key}++;
            my $template = delete $args->{template_index}->{$key};

            if (ref($template) eq 'HASH' && $template->{patch}) {
                # apply patch
                eval "require Text::Patch;";
                die $@ if $@;
                $template->{template} = Text::Patch::patch( $tmpl->{template}, $template->{patch}, STYLE => 'Unified' );
            }

            $template = $tmpl unless $template;
            push @template, $template;
            next LOOP;
        }
        push @template, $tmpl;
    }

    @template;
}

sub import_template {
    my($self, @base_classes) = @_;
    my $class = ref($self);

    my @local_template = loader($self);

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

    my $args = {
        template_config => $template_config,
        template_index  => \%template_index,
    };
    my @template;
    for my $base_class (reverse @base_classes) {
        push @template, $self->_import_template($base_class, $args);
    }

    for my $tmpl (values %{ $args->{template_index} }) {
        push @template, $tmpl;
    }
    push @template, $args->{template_config} if $args->{template_config};

    @template;
}

sub setup_flavor { 1 }

sub setup_config {
    my($self, $context, $config) = @_;
}

sub setup_additional {
    my($self, $context, $config) = @_;
}


1;

=head1 NAME

Module::Setup::Flavor - Module::Setup Flavor

=head1 Flavor Hook Point

=head2 setup_flavor

flavor setup, if return value is false is exit create flavor

=head2 setup_config

before flavors plugin load

=head2 setup_additional

end of additional flavor install

=cut

__DATA__
