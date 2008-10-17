use t::Utils;
use Test::More tests => 4;

module_setup { flavor_class => '+t::Flavor::EmptyDir', target => 1 }, 'EmptyDir';

ok -d template_dir 'default' => 'foo', 'bar', 'baz';
ok -d target_dir 'EmptyDir', 'foo', 'bar', 'baz';

module_setup { pack => 1 }, 'FlavorEmptyDir';

like stdout->[0], qr/package FlavorEmptyDir;/;
like stdout->[0], qr!dir: foo/bar/baz!;

