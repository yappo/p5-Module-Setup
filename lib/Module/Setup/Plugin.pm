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

__END__

=head1 NAME

Module::Setup::Plugin - Module::Setup Plugin

=head1 Trigger Point

=head2 befor_dump_config $config

config setup L<Module::Setup::Plugin::Config::Basic>

=head2 after_setup_module_attribute

module attribute setup L<Module::Setup::Plugin::VC::SVN>

=head2 after_setup_template_vars

template parameters setup

=head2 append_template_file $template_vars, $module_attribute

add module template file for new module L<Module::Setup::Plugin::VC::Git>

=head2 template_process $options

for template process L<Module::Setup::Plugin::Template>

=head2 check_skeleton_directory

=head1 Plugin Example

~/.module-setup/flavor/myflavor/plugins/plugin.pl
  package MyFlavor::Plugin;
  use strict;
  use warnings;
  use base 'Module::Setup::Plugin';

  use Path::Class;

  sub register {
      my($self, ) = @_;
      $self->add_trigger( check_skeleton_directory => \&check_skeleton_directory );
  }

  sub check_skeleton_directory {
      my $self = shift;
  }

~/.module-setup/flavor/myflavor/config.yaml

  config:
    plugins:
      - Config::Basic
      - VC::SVN
      - Template
      - Test::Makefile
      - +MyFlavor::Plugin

or command option

  $ module-setup --plugin=+MyFlavor::Plugin New::Module

=cut


