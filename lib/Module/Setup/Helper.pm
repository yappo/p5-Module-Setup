package Module::Setup::Helper;
use strict;
use warnings;
use base 'Module::Setup::Flavor';

use Module::Setup;

sub new {
    my($class, %args) = @_;
    my $self = bless {
        argv         => [],
        options      => {},
        %args,
    }, $class;

    $self->{options}->{flavor_class} = "+$class";

    $self->helper_base_init;
    $self->helper_flavor_init;
    $self;
}
sub helper_base_init {
    my $self = shift;
    $self->{options}->{module} = shift @{ $self->{argv} };
}
sub helper_flavor_init {}
sub helper_default_plugins { qw/ Template Helper / }

sub helper_option_prefix { die "$_[0] class is not implement helper_option_prefix method" }
sub generate_path_option_names { qw// }
sub is_append_files { 0 }

sub run {
    my $self = shift;

    # set the direct run mode
    $self->{options}->{direct} = 1;

    # add default plugins
    $self->{options}->{plugins} ||= [];
    push @{ $self->{options}->{plugins} }, $self->helper_default_plugins;

    $self->before_run;

    my $setup = Module::Setup->new(
        argv    => [ $self->{options}->{module}, @{ $self->{argv} } ],
        options => $self->{options},
        helper  => $self->{helper},
    );
    $setup->run;
}

sub before_run {}

1;

=head1 NAME

Module::Setup::Helper - build in your application helper support

=head1 SYNOPSIS

script/helper.pl is your helper script

  use strict;
  use warnings;

  my $type = shift @ARGV;
  my $helper = "YourApp::Helper::$type";
  eval "use $helper";

  $helper->new(
      argv    => [ @ARGV ],
      options => {
          # Module::Setup's options
      },
      helper => {
          option => 'FOO_OPTION',
      },
  )->run;

lib/YourApp/Helper.pm is your application helper base class.

  package YourApp::Helper;
  use strict;
  use warnings;
  use base 'Module::Setup::Helper';

  # make your application's options name prefix
  sub helper_option_prefix { 'yourapp' }

  sub helper_base_init {
      my $self = shift;

      # auto detect app module name by Makefile.PL
      open my $fh, '<', 'Makefile.PL' or die $!;
      local $/;
      my $makefile = <$fh>;
      my($module) = $makefile =~ /all_from 'lib/(.+).pm'/;
      unless ($module) {
          return $self->{options}->{module} = shift @{ $self->{argv} };
      }
      $module =~ s{/}{::}g;
      $self->{options}->{module} = $module;
  }



  1;

lib/YourApp/Helper/Controller.pm is your application helper for controller

  package YourApp::Helper::Controller;
  use strict;
  use warnings;
  use base 'YourApp::Helper';

  sub generate_path_option_names { qw/ target / }
  sub is_append_files { 1 } # append type helper

  sub helper_flavor_init {
      my $self = shift;

      # auto detect target name by @ARGV
      my $target = $self->{argv}->[0];
      die 'required target name' unless $target;
      $self->{helper}->{target} = $target;
  }

  1;
  
  __DATA__
  ---
  file: lib/____var-module_path-var____/Controller/____var-yourapp_target_path-var____.pm
  template: |
    package [% module %]::Controller::[% yourapp_target %];
    use base 'YourApp::Controller';

    my $option = '[% yourapp_option %]';

    ... some code

    1;
  file: t/100_controller/____var-yourapp_target_path-var____.t
  template: |
    use Test::More tests => 1;
    use_ok '[% yourapp_app %]::Controller::[% yourapp_target %]';

run the script/helper.pl

  $ perl ./script/helper.pl Controller Search
  $ cat lib/Foo/Controller/Search.pm
  package Foo::Controller::Search;
  use base 'YourApp::Controller';

  my $option = 'FOO_OPTION';

  ... some code

  1;
  $ cat t/100_controller/Search.t
    use Test::More tests => 1;
    use_ok 'Foo::Controller::Search';

=head1 Helper Hook Point

=head2 helper_option_prefix (required)

When using config of helper by template, prefix specified here is used.

  sub helper_option_prefix { 'foo' }

in your flavor's template

  [% foo_bar %]
  # use the $self->{helper}->{bar}

=head2 is_append_files

When this function returns truth, flavor is added to the existing application.

  sub is_append_files { 1 } # default is false

It is the same work as the time helper of adding Controller of Catalyst.

=head2 helper_base_init

helper initialize phase for your application helper base class

  # default
  sub helper_base_init {
      my $self = shift;
      $self->{options}->{module} = shift @{ $self->{argv} };
  }

you can set the base module name

=head2 helper_flavor_init

helper initialize phase for flavor class

  sub helper_flavor_init {
      my $self = shift;
      $self->{helper} = {
          # some options for helper
      };
  }

you can set the target module name, or more options for helper

=head3 $helper->{helper}->{setup_template_vars_callback}

you can set the callback for setup_template_vars phase

  sub helper_flavor_init {
      my $self = shift;
      # set callback handler for setup_template_vars hook point
      $self->{helper}->{setup_template_vars_callback} = sub {
          my($setup, $vars) = @_;
          $vars->{callback_var} = 'this is callback var';
          $vars->{callback_path} = 'callback/path';
      };
  }

example is C<t/Helper/Basic/Callback.pm>

=head2 helper_default_plugins

Plugin which helper uses is listed.

  # default
  sub helper_default_plugins { qw/ Template Helper / }

=head2 before_run

It is a phase just before helper actually starts Module::Setup.

=cut
