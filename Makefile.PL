use inc::Module::Install;
name 'Module-Setup';
all_from 'lib/Module/Setup.pm';

requires 'Class::Trigger';
requires 'ExtUtils::MakeMaker';
requires 'File::Basename';
requires 'File::Find::Rule';
requires 'File::Path';
requires 'File::Temp';
requires 'Getopt::Long';
requires 'Module::Collect' => 0.03;
requires 'Path::Class';
requires 'Pod::Usage';
requires 'Scalar::Util';
requires 'Template';
requires 'YAML';

build_requires 'Test::More';
use_test_base;
auto_include;

install_script('bin/module-setup');

WriteAll;
