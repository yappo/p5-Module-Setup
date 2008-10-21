use t::Utils;
use Test::More tests => 6;

module_setup { flavor_class => '+t::Flavor::LocalPlugin', target => 1 }, 'LocalPlugin';

ok -f plugins_dir('default')->file('localplugin.pm');
ok -f template_dir('default')->file('test.txt');

ok -f target_dir('LocalPlugin')->file('test.txt');
ok -f target_dir('LocalPlugin')->file('append.txt');


no warnings 'redefine';
my $flavor;
*Module::Setup::stdout = sub { $flavor = $_[1] };
module_setup { pack => 1, }, 'LocalPlugin';

like $flavor, qr/package LocalPlugin;/;
like $flavor, qr!plugin: localplugin.pm!;

