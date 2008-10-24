package Module::Setup::Flavor::PBP;
use strict;
use warnings;
use base 'Module::Setup::Flavor';

sub setup_config {
    my($class, $context, $config) = @_;

    my %vcs = (
        SVN => 'VC::SVN',
        SVK => 'VC::SVK',
        Git => 'VC::Git',
    );

    for my $name (qw/ SVN SVK Git /) {
        my $pkg = $vcs{$name};
        next unless $context->dialog("Do you use $name? [yN]", 'n') =~ /[Yy]/;
        $context->log("You chose version control system: $name");

        next if grep {
            ( ref($_) eq 'HASH' && $_->{module} eq $pkg) || $_ eq $pkg
        } @{ $config->{plugins} };

        push @{ $config->{plugins} }, $pkg;
    }

    if(grep {
        ( ref($_) eq 'HASH' && $_->{module} eq 'VC::SVK') || $_ eq 'VC::SVK'
    } @{ $config->{plugins} }) {
        my @plugins = grep {
            !(( ref($_) eq 'HASH' && $_->{module} eq 'VC::SVN') || $_ eq 'VC::SVN')
        } @{ $config->{plugins} };
        $config->{plugins} = \@plugins;
    }

}

1;

=head1

PBP - pack from pbp

=head1 SYNOPSIS

  PBP-setup --init --flavor-class=+PBP new_flavor

=cut

__DATA__

---
file: Build.PL
template: |
  use strict;
  use warnings;
  use Module::Build;
  
  my $builder = Module::Build->new(
      module_name         => '[% module %]',
      license             => '[% config.plugin_pbp_license %]',
      dist_author         => '[% config.author %] <[% config.email %]>',
      dist_version_from   => 'lib/[% module_unix_path %].pm',
      requires => {
          'Test::More' => 0,
          'version'    => 0,
      },
      add_to_cleanup      => [ '[% dist %]-*' ],
  );
  
  $builder->create_build_script();
---
file: Makefile.PL
template: |+
  use strict;
  use warnings;
  use ExtUtils::MakeMaker;
  
  WriteMakefile(
      NAME          => '[% module %]',
      AUTHOR        => '[% config.author %] <[% config.email %]>>',
      VERSION_FROM  => 'lib/[% module_unix_path %].pm',
      ABSTRACT_FROM => 'lib/[% module_unix_path %].pm',
      PL_FILES      => {},
      PREREQ_PM     => {
          'Test::More' => 0,
          'version'    => 0,
      },
      dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
      clean => { FILES    => '[% dist %]-*' },
  );

---
file: Changes
template: |
  Revision history for [% module %]
  
  0.0.1    [% localtime %]
          - Initial release
---
file: README
template: |
  [% dist %] version 0.0.1
  
  [ REPLACE THIS...
  
    The README is used to introduce the module and provide instructions on
    how to install the module, any machine dependencies it may have (for
    example C compilers and installed libraries) and any other information
    that should be understood before the module is installed.
  
    A README file is required for CPAN modules since CPAN extracts the
    README file from a module distribution so that people browsing the
    archive can use it get an idea of the modules uses. It is usually a
    good idea to provide version information here so that people can
    decide whether fixes for the module are worth downloading.
  ]
  
  
  INSTALLATION
  
  To install this module, run the following commands:
  
  	perl Makefile.PL
  	make
  	make test
  	make install
  
  Alternatively, to install with Module::Build, you can use the following commands:
  
  	perl Build.PL
  	./Build
  	./Build test
  	./Build install
  
  
  DEPENDENCIES
  
  None.
  
  
  COPYRIGHT AND LICENCE
  
  Copyright (C) [% pbp_year %] [% config.author %]
  
  This library is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself.
---
file: lib/____var-module_path-var____.pm
template: |
  package [% module %];
  
  use strict;
  use warnings;
  use Carp;
  
  use version; our $VERSION = qv('0.0.1');
  
  # Other recommended modules (uncomment to use):
  #  use IO::Prompt;
  #  use Perl6::Export;
  #  use Perl6::Slurp;
  #  use Perl6::Say;
  
  
  # Module implementation here
  
  
  1; # Magic true value required at end of module
  __END__
  
  =head1 NAME
  
  [% module %] - [One line description of module's purpose here]
  
  
  =head1 VERSION
  
  This document describes [% module %] version 0.0.1
  
  
  =head1 SYNOPSIS
  
      use [% module %];
  
  =for author to fill in:
      Brief code example(s) here showing commonest usage(s).
      This section will be as far as many users bother reading
      so make it as educational and exeplary as possible.
    
    
  =head1 DESCRIPTION
  
  =for author to fill in:
      Write a full description of the module and its features here.
      Use subsections (=head2, =head3) as appropriate.
  
  
  =head1 INTERFACE 
  
  =for author to fill in:
      Write a separate section listing the public components of the modules
      interface. These normally consist of either subroutines that may be
      exported, or methods that may be called on objects belonging to the
      classes provided by the module.
  
  
  =head1 DIAGNOSTICS
  
  =for author to fill in:
      List every single error and warning message that the module can
      generate (even the ones that will "never happen"), with a full
      explanation of each problem, one or more likely causes, and any
      suggested remedies.
  
  =over
  
  =item C<< Error message here, perhaps with %s placeholders >>
  
  [Description of error here]
  
  =item C<< Another error message here >>
  
  [Description of error here]
  
  [Et cetera, et cetera]
  
  =back
  
  
  =head1 CONFIGURATION AND ENVIRONMENT
  
  =for author to fill in:
      A full explanation of any configuration system(s) used by the
      module, including the names and locations of any configuration
      files, and the meaning of any environment variables or properties
      that can be set. These descriptions must also include details of any
      configuration language used.
    
  [% module %] requires no configuration files or environment variables.
  
  
  =head1 DEPENDENCIES
  
  =for author to fill in:
      A list of all the other modules that this module relies upon,
      including any restrictions on versions, and an indication whether
      the module is part of the standard Perl distribution, part of the
      module's distribution, or must be installed separately. ]
  
  None.
  
  
  =head1 INCOMPATIBILITIES
  
  =for author to fill in:
      A list of any modules that this module cannot be used in conjunction
      with. This may be due to name conflicts in the interface, or
      competition for system or program resources, or due to internal
      limitations of Perl (for example, many modules that use source code
      filters are mutually incompatible).
  
  None reported.
  
  
  =head1 BUGS AND LIMITATIONS
  
  =for author to fill in:
      A list of known problems with the module, together with some
      indication Whether they are likely to be fixed in an upcoming
      release. Also a list of restrictions on the features the module
      does provide: data types that cannot be handled, performance issues
      and the circumstances in which they may arise, practical
      limitations on the size of data sets, special cases that are not
      (yet) handled, etc.
  
  No bugs have been reported.
  
  Please report any bugs or feature requests to
  C<bug-[% pbp_rt_name %]@rt.cpan.org>, or through the web interface at
  L<http://rt.cpan.org>.
  
  
  =head1 AUTHOR
  
  [% config.authot %]  C<< <[% config.email %]> >>
  
  
  =head1 LICENCE AND COPYRIGHT
  
  Copyright (c) [% pbp_year %], [% config.author %] C<< <[% config.email %]> >>. All rights reserved.
  
  This module is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself. See L<perlartistic>.
  
  
  =head1 DISCLAIMER OF WARRANTY
  
  BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
  FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
  OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
  PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
  EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
  ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
  YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
  NECESSARY SERVICING, REPAIR, OR CORRECTION.
  
  IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
  WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
  REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
  LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
  OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
  THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
  RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
  FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
  SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
  SUCH DAMAGES.
---
file: t/perlcritic.t
template: |
  #!perl
  
  if (!require Test::Perl::Critic) {
      Test::More::plan(
          skip_all => "Test::Perl::Critic required for testing PBP compliance"
      );
  }
  
  Test::Perl::Critic::all_critic_ok();
---
file: t/00.load.t
template: |
  use Test::More tests => 1;
  
  BEGIN {
  use_ok( '[% module %]' );
  }
  
  diag( "Testing [% module %] $[% module %]::VERSION" );
---
file: t/pod.t
template: |
  #!perl -T
  
  use Test::More;
  eval "use Test::Pod 1.14";
  plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
  all_pod_files_ok();
---
file: t/pod-coverage.t
template: |
  #!perl -T
  
  use Test::More;
  eval "use Test::Pod::Coverage 1.04";
  plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
  all_pod_coverage_ok();
---
plugin: PBP.pm
template: |+
  package OreOre::Hide::Module::Setup::Plugin::PBP;
  use strict;
  use warnings;
  use base 'Module::Setup::Plugin';
  
  sub register {
      my ( $self, ) = @_;
  
      $self->add_trigger( 'befor_dump_config' => \&befor_dump_config );
      $self->add_trigger(
          'after_setup_template_vars' => \&after_setup_template_vars );
  }
  
  sub befor_dump_config {
      my ( $self, $config ) = @_;
  
      $config->{plugin_pbp_license} ||= 'perl';
      $config->{plugin_pbp_license}
          = $self->dialog( "License: ", $config->{plugin_pbp_license} );
  }
  
  sub after_setup_template_vars {
      my ( $self, $config ) = @_;
  
      my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst )
          = localtime;
      my $new_config = +{
          'pbp_year'    => $year + 1900,
          'pbp_rt_name' => lc $self->distribute->{dist_name},
      };
  
      while ( my ( $key, $val ) = each %{$new_config} ) {
          $config->{$key} = $val;
      }
  }
  
  1;

---
config:
  plugins:
    - Config::Basic
    - Template
    - +OreOre::Hide::Module::Setup::Plugin::PBP
    - Test::Makefile
    - Additional


