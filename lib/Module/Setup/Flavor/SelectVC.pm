package Module::Setup::Flavor::SelectVC;
use strict;
use warnings;
use base 'Module::Setup::Flavor';

sub setup_config {
    my($self, $context, $config) = @_;

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

Module::Setup::Flavor::SelectVC - select version control system logic

=head1 SYNOPSIS

  package YourFlavor;
  use base 'Module::Setup::Flavor::SelectVC';
  1;
  
  __DATA__
  
  ---
  file: foo
  template: bar
  
  ...

=cut

