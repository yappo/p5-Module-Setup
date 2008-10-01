package Module::Setup::Plugin::VC::Git;
use strict;
use warnings;
use base 'Module::Setup::Plugin';

use Path::Class;

sub register {
    my($self, ) = @_;
    $self->add_trigger( check_skeleton_directory => \&check_skeleton_directory );
    $self->add_trigger( append_template_file     => sub { $self->append_template_file(@_) } );
}

sub check_skeleton_directory {
    my $self = shift;
    return unless $self->dialog("Git init? [Yn] ", 'y') =~ /[Yy]/;

    !system 'git init' or die $?;
    !system "git add .gitignore" or die $?;

    my $dir = Path::Class::Dir->new('.');
    while (my $path = $dir->next) {
        next if $path eq '.' || $path eq '..' || $path eq '.git' || $path eq '.gitignore';
        system 'git', 'add', $path;
    }
    !system 'git commit -m "initial commit"' or die $?;
}

1;

# original http://gist.github.com/13374 by dann

__DATA__

---
 file: .gitignore
 template: |
  Makefile.PL
  cover_db
  META.yml
  Makefile
  blib
  inc
  pm_to_blib
  MANIFEST
  Makefile.old
