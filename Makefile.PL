use inc::Module::Install;
name 'Module-Setup';
all_from 'lib/Module/Setup.pm';

requires 'Class::Trigger';
requires 'ExtUtils::MakeMaker';
requires 'File::Basename';
requires 'File::Find::Rule';
requires 'File::Path';
requires 'File::Temp'      => 0.20;
requires 'Getopt::Long';
requires 'Module::Collect' => 0.04;
requires 'Path::Class';
requires 'Pod::Usage';
requires 'Scalar::Util';
requires 'Template'        => 2.20;
requires 'YAML';

# for author_tests in Flavor::Default
requires 'Module::Install::AuthorTests';

tests 't/*.t t/*/*.t';

build_requires 'Test::More';
build_requires 'IO::Scalar';
use_test_base;
auto_include;

install_script('bin/module-setup');

WriteAll;
