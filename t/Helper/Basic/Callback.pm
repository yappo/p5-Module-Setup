package t::Helper::Basic::Callback;
use strict;
use warnings;
use base 't::Helper::Basic';

sub is_append_files { 1 }

sub helper_flavor_init {
    my $self = shift;
    $self->{helper}->{setup_template_vars_callback} = sub {
        my($setup, $vars) = @_;
        $vars->{callback_var} = 'this is callback var';
        $vars->{callback_path} = 'callback/path';
    };
}

1;

__DATA__

---
file: ____var-callback_path-var____.txt
template: |
  [% callback_var %]
