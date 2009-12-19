package Module::Setup::Flavor::CodeRepos;
use strict;
use warnings;
use base 'Module::Setup::Flavor';

sub loader {
    my $self = shift;
    $self->import_template('Module::Setup::Flavor::Default');
}

1;

=head1

Module::Setup::Flavor::CodeRepos - coderepos flavor

=head1 SYNOPSIS

  $ module-setup --init --flavor-class=CodeRepos new_flavor

=cut

__DATA__

file: lib/____var-module_path-var____.pm
patch: |
  @@ -24,6 +24,13 @@
   
   =head1 SEE ALSO
   
  +=head1 REPOSITORY
  +
  +  svn co http://svn.coderepos.org/share/lang/perl/[% dist %]/trunk [% dist %]
  +
  +[% module %] is Subversion repository is hosted at L<http://coderepos.org/share/>.
  +patches and collaborators are welcome.
  +
   =head1 LICENSE
   
   This library is free software; you can redistribute it and/or modify
