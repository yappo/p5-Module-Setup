package Module::Setup::Plugin::Template;
use strict;
use warnings;
use base 'Module::Setup::Plugin';

use Template;

my $TEMPLATE;
sub register {
    my($self, ) = @_;
    $self->{config} = +{} unless $self->{config};
    $TEMPLATE = Template->new(%{ $self->{config} });
    $self->add_trigger( template_process => \&template_process );
}

sub template_process {
    my($self, $opts) = @_;
    return unless $opts->{template};
    my $template = delete $opts->{template};;
    $TEMPLATE->process(\$template, $opts->{vars}, \my $content);
    $opts->{content} = $content;
}

1;
