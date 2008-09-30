package Module::Setup::Flavor::Default;
use strict;
use warnings;

1;


=head1

Module::Setup::Flavor::Default - default flavor

=head1 SYNOPSIS

  $ module-setup --flavor=foo # default flavor class is this

=cut

__DATA__

---
file: Makefile.PL
template: |
  use inc::Module::Install;
  name '[% dist %]';
  all_from 'lib/[% path %]';

  # requires '';

  build_requires 'Test::More';
  use_test_base;
  auto_include;
  WriteAll;
---
file: t/00_compile.t
template: |
  use strict;
  use Test::More tests => 1;

  BEGIN { use_ok '[% module %]' }
---
file: xt/01_podspell.t
template: |
  use Test::More;
  eval q{ use Test::Spelling };
  plan skip_all => "Test::Spelling is not installed." if $@;
  add_stopwords(map { split /[\s\:\-]/ } <DATA>);
  $ENV{LANG} = 'C';
  all_pod_files_spelling_ok('lib');
  __DATA__
  [% config.author %]
  [% module %]
---
file: xt/02_perlcritic.t
template: |
  use strict;
  use Test::More;
  eval {
      require Test::Perl::Critic;
      Test::Perl::Critic->import( -profile => 't/perlcriticrc');
  };
  plan skip_all => "Test::Perl::Critic is not installed." if $@;
  all_critic_ok('lib');
---
file: xt/03_pod.t
template: |
  use Test::More;
  eval "use Test::Pod 1.00";
  plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
  all_pod_files_ok();
---
file: xt/perlcriticrc
template: |
  [TestingAndDebugging::ProhibitNoStrict]
  allow=refs
---
file: Changes
template: |
  Revision history for Perl extension [% module %]

  0.01    [% localtime %]
          - original version
---
file: lib/____var-modulepath-var____.pm
template: |
  package [% module %];

  use strict;
  use warnings;
  our $VERSION = '0.01';

  1;
  __END__

  =encoding utf8

  =head1 NAME

  [% module %] -

  =head1 SYNOPSIS

    use [% module %];

  =head1 DESCRIPTION

  [% module %] is

  =head1 AUTHOR

  [% config.author %] E<lt>[% config.email %]E<gt>

  =head1 SEE ALSO

  =head1 LICENSE

  This library is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself.

  =cut
---
file: MANIFEST.SKIP
template: |
  \bRCS\b
  \bCVS\b
  ^MANIFEST\.
  ^Makefile$
  ~$
  ^#
  \.old$
  ^blib/
  ^pm_to_blib
  ^MakeMaker-\d
  \.gz$
  \.cvsignore
  ^t/9\d_.*\.t
  ^t/perlcritic
  ^tools/
  \.svn/
  ^[^/]+\.yaml$
  ^[^/]+\.pl$
  ^\.shipit$
---
file: README
template: |
  This is Perl module [% module %].

  INSTALLATION

  [% module %] installation is straightforward. If your CPAN shell is set up,
  you should just be able to do

      % cpan [% module %]

  Download it, unpack it, then build it as per the usual:

      % perl Makefile.PL
      % make && make test

  Then install it:

      % make install

  DOCUMENTATION

  [% module %] documentation is available as in POD. So you can do:

      % perldoc [% module %]

  to read the documentation online with your favorite pager.

  [% config.author %]
---
file: .shipit
chmod: 0644
template: |
  steps = FindVersion, ChangeVersion, CheckChangeLog, DistTest, Commit, Tag, MakeDist, UploadCPAN
  svk.tagpattern = release-%v
