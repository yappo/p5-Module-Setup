package Module::Setup::Flavor::XS;
use strict;
use warnings;
use base 'Module::Setup::Flavor';

sub loader {
    my $self = shift;
    $self->import_template('Module::Setup::Flavor::Default');
}

1;

=head1

Module::Setup::Flavor::XS - coderepos flavor

=head1 SYNOPSIS

  $ module-setup --init --flavor-class=XS new_flavor

=cut

__DATA__

---
file: lib/____var-module_path-var____.pm
template: |
  package [% module %];
  use strict;
  use warnings;
  our $VERSION = '0.01';

  eval {
      require XSLoader;
      XSLoader::load(__PACKAGE__, $VERSION);
      1;
  } or do {
      require DynaLoader;
      push @ISA, 'DynaLoader';
      __PACKAGE__->bootstrap($VERSION);
  };

  1;
  __END__

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
file: Makefile.PL
template: |
  use inc::Module::Install;
  name '[% dist %]';
  all_from 'lib/[% module_unix_path %].pm';

  can_cc or die "This module requires a C compiler";
  makemaker_args(
      OBJECT => '$(O_FILES)',
      clean => {
          FILES => q{
              *.stackdump
              *.gcov *.gcda *.gcno
              *.out
              nytprof
              cover_db
          },
      },
  );

  tests 't/*.t';
  author_tests 'xt';

  build_requires 'Test::More';
  use_test_base;
  auto_include;
  WriteAll;
---
file: typemap
template: |
  TYPEMAP
  YourType*      T_YOUR_TYPE
  
  INPUT
  T_YOUR_TYPE
      $var = XS_STATE(YourType*, $arg);
  
  OUTPUT
  T_YOUR_TYPE
      XS_STRUCT2OBJ($arg, "[% module %]", $var);
---
file: ____var-moniker-var____.xs
template: |
  #ifdef __cplusplus
  extern "C" {
  #endif
  #include "EXTERN.h"
  #include "perl.h"
  #include "XSUB.h"
  #include "ppport.h"
  #ifdef __cplusplus
  }
  #endif
  
  #define XS_STATE(type, x) \
      INT2PTR(type, SvROK(x) ? SvIV(SvRV(x)) : SvIV(x))
  
  #define XS_STRUCT2OBJ(sv, class, obj) \
      if (obj == NULL) { \
          sv_setsv(sv, &PL_sv_undef); \
      } else { \
          sv_setref_pv(sv, class, (void *) obj); \
      }
  
  MODULE = [% module %]  PACKAGE = [% module %]
  
  YourType*
  [% module %]::new()
  CODE:
      YourType* self = your_type_new();
      RETVAL = self;
  OUTPUT:
      RETVAL
  
  void
  DESTROY(YourType* self)
  CODE:
      your_type_free(self);
  
