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
requires 'LWP::UserAgent';
requires 'Module::Collect' => 0.04;
requires 'Path::Class';
requires 'Pod::Usage';
requires 'Scalar::Util';
requires 'Storable';
requires 'Template'        => 2.20;
requires 'YAML';
requires 'Module::Install::Repository';

requires 'Text::Patch';

# for author_tests in Flavor::Default
requires 'Module::Install::AuthorTests';

tests 't/*.t t/*/*.t';

test_requires 'IO::Scalar';
test_requires 'Test::More';
test_requires 'Test::Requires';

use_test_base;
auto_include;
auto_set_repository;

install_script('bin/module-setup');

WriteAll;
