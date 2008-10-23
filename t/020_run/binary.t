use t::Utils;
use Test::More tests => 13;
use YAML ();

default_dialog;
module_setup { init => 1, flavor_class => '+t::Flavor::Binary' };
ok -f template_dir('default')->file('fujisan.jpg');
ok -B template_dir('default')->file('fujisan.jpg');
ok -f template_dir('default')->file('fujisan.html');
ok -T template_dir('default')->file('fujisan.html');
unlike template_dir('default')->file('fujisan.jpg')->slurp, qr/ffd8ffe000104a46494600010101004800480000ffe2112c4943435f50524f46494c450001010000111c6170706c020000006d6e74725/;

module_setup { target => 1 }, 'Bin';
ok -f target_dir('Bin')->file('fujisan.jpg');
ok -B target_dir('Bin')->file('fujisan.jpg');
ok -f target_dir('Bin')->file('fujisan.html');
ok -T target_dir('Bin')->file('fujisan.html');
unlike target_dir('Bin')->file('fujisan.jpg')->slurp, qr/ffd8ffe000104a46494600010101004800480000ffe2112c4943435f50524f46494c450001010000111c6170706c020000006d6e74725/;

module_setup { pack => 1 }, 'Bin';
like stdout->[0], qr/file: fujisan.jpg/;
like stdout->[0], qr/is_binary: 1/;

do {
    my $module = stdout->[0];
    $module =~ s/^.+__DATA__(.+)$/$1/s;
    my @data = YAML::Load(join '', $module);
    
    my($packed) = grep { exists $_->{file} && $_->{file} eq 'fujisan.jpg' } @data;
    my($loader) = grep { exists $_->{file} && $_->{file} eq 'fujisan.jpg' } t::Flavor::Binary->new->loader;
    is_deeply $packed, $loader;
};
