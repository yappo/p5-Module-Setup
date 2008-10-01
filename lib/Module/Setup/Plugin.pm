package Module::Setup::Plugin;
use strict;
use warnings;

use Path::Class;
use Scalar::Util qw(weaken);

use Module::Setup::Flavor;

sub new {
    my($class, %args) = @_;
    my $self = bless { %args }, $class;
    weaken $self->{context};
    $self->register;
    $self;
}

sub register {}

sub add_trigger {
    my($self, @args) = @_;
    $self->{context}->add_trigger(@args);
}

sub append_template_file {
    my($self, $context, $template_vars, $module_attribute) = @_;
    my $caller = caller;

    my @template = Module::Setup::Flavor::loader($caller);

    for my $tmpl (@template) {
        next unless exists $tmpl->{file};
        my $dist_path = Path::Class::File->new(@{ $module_attribute->{dist_path} }, $tmpl->{file});

        my $options = {
            dist_path => $dist_path,
            template  => $tmpl->{template},
            vars      => $template_vars,
            content   => undef,
        };
        $options->{chmod} = $tmpl->{chmod} if $tmpl->{chmod};
        $context->write_template($options);
    }
}

1;
