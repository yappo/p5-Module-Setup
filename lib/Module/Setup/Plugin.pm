package Module::Setup::Plugin;
use strict;
use warnings;

use Scalar::Util qw(weaken);

use Module::Setup::Flavor;
use Module::Setup::Path::Dir;

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
    my($self, $context, $caller) = @_;
    $caller = caller unless $caller;
    my @template = Module::Setup::Flavor::loader($caller);

    for my $tmpl (@template) {
        if (exists $tmpl->{dir}) {
            Module::Setup::Path::Dir->new($context->distribute->dist_path, split('/', $tmpl->{dir}))->mkpath;
            next;
        } elsif (!exists $tmpl->{file}) {
            next;
        }
        my $options = {
            dist_path => $context->distribute->dist_path->file(split('/', $tmpl->{file})),
            template  => $tmpl->{template},
            vars      => $context->distribute->template_vars,
            content   => undef,
        };
        $options->{chmod} = $tmpl->{chmod} if $tmpl->{chmod};
        $context->distribute->write_template($context, $options);
    }
}

1;

__END__

=head1 NAME

Module::Setup::Plugin - Module::Setup Plugin

=head1 Trigger Point

=head2 before_dump_config $config

config setup L<Module::Setup::Plugin::Config::Basic>

=head2 after_setup_module_attribute

module attribute setup L<Module::Setup::Plugin::VC::SVN>

=head2 after_setup_template_vars

template parameters setup

=head2 append_template_file

add module template file for new module L<Module::Setup::Plugin::VC::Git>

=head2 template_process $options

for template process L<Module::Setup::Plugin::Template>

=head2 replace_distribute_path $options

for distribute path rewrite phase

=head2 check_skeleton_directory

  for test L<Module::Setup::Plugin::Test::Makefile>

=head2 after_create_skeleton

after create_skeleton

=head2 finalize_create_skeleton

last trigger of run method on skeleton directory

=head2 finish_of_run

last hook of run method L<Module::Setup::Plugin::VC::SVK>

=head1 Plugin Example

~/.module-setup/flavor/myflavor/plugins/plugin.pm
  package MyFlavor::Plugin;
  use strict;
  use warnings;
  use base 'Module::Setup::Plugin';

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


