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

    !$self->system('git', 'init')              or die $?;
    !$self->system('git', 'add', '.gitignore') or die $?;

    my $dir = Path::Class::Dir->new('.');
    while (my $path = $dir->next) {
        next if $path eq '.' || $path eq '..' || $path eq '.git';
        $self->system('git', 'add', $path);
    }
    !$self->system('git', 'commit', '-m', 'initial commit') or die $?;
}

1;


=head1 NAME

Module::Setup::Plugin::VC::Git - Git plugin

=head1 SYNOPSIS

  module-setup --init --plugin=VC::Git

=head1 SEE ALSO

original L<http://gist.github.com/13374> by dann

=cut

__DATA__

---
 file: .gitignore
 template: |
  cover_db
  META.yml
  Makefile
  blib
  inc
  pm_to_blib
  MANIFEST
  Makefile.old
