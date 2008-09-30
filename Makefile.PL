use inc::Module::Install;
name 'Module-Setup';
all_from 'lib/Module/Setup.pm';

requires 'ExtUtils::MakeMaker';
requires 'File::Basename';
requires 'File::Find::Rule';
requires 'File::Path';
requires 'File::Spec';
requires 'Getopt::Long';
requires 'Pod::Usage';
requires 'Template';
requires 'YAML';

build_requires 'Test::More';
use_test_base;
auto_include;

install_script('bin/module-setup');

WriteAll;
