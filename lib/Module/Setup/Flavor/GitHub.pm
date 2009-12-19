package Module::Setup::Flavor::GitHub;
use strict;
use warnings;
use base 'Module::Setup::Flavor';

sub loader {
    my $self = shift;
    $self->import_template('Module::Setup::Flavor::Default');
}

sub setup_config {
    my($self, $context, $config) = @_;
    push @{ $config->{plugins} }, 'VC::Git', 'Site::GitHub';
}

1;

=head1

Module::Setup::Flavor::GutHub - GitHub flavor

=head1 SYNOPSIS

  $ module-setup --init --flavor-class=GitHub new_flavor

=cut

__DATA__

---
file: Makefile.PL
template: |
  use inc::Module::Install;
  name '[% dist %]';
  all_from 'lib/[% module_unix_path %].pm';
  [% IF config.readme_from -%]
  readme_from 'lib/[% module_unix_path %].pm';
  [% END -%]
  [% IF config.readme_markdown_from -%]
  readme_markdown_from 'lib/[% module_unix_path %].pm';
  [% END -%]
  [% IF config.readme_pod_from -%]
  readme_pod_from 'lib/[% module_unix_path %].pm';
  [% END -%]
  [% IF config.githubmeta -%]
  githubmeta;
  [% END -%]

  # requires '';

  tests 't/*.t';
  author_tests 'xt';

  build_requires 'Test::More';
  auto_set_repository;
  auto_include;
  WriteAll;
