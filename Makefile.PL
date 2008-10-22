use inc::Module::Install;
use 5.008001;
name 'Module-Setup';
all_from 'lib/Module/Setup.pm';

requires 'Class::Trigger';
requires 'Cwd';
requires 'ExtUtils::MakeMaker';
requires 'File::Basename';
requires 'File::Find::Rule';
requires 'File::HomeDir';
requires 'File::Path';
requires 'File::Temp'      => 0.20;
requires 'Getopt::Long';
requires 'Module::Collect' => 0.04;
requires 'Path::Class';
requires 'Pod::Usage';
requires 'Scalar::Util';
requires 'Storable';
requires 'Template'        => 2.20;
requires 'YAML';

# for author_tests in Flavor::Default
requires 'Module::Install::AuthorTests';

tests 't/*.t t/*/*.t';

build_requires 'IO::Scalar';
build_requires 'Test::More';
use_test_base;
auto_include;

install_script('bin/module-setup');

WriteAll;
