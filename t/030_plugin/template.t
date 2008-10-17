use t::Utils;
use Test::More tests => 3;
use Fcntl qw( :mode );

default_dialog;
module_setup { target => 1, flavor_class => '+t::Flavor::Simple', plugins => [
    'Template',
    {
        module => 'Template',
        config => +{
            COMPILE_DIR => target_dir 'tt_cache',
        },
    }
] }, 'TemplateModule';

ok -d target_dir 'tt_cache';
ok -f target_dir('TemplateModule')->file('simple.txt');
like target_dir('TemplateModule')->file('simple.txt')->slurp, qr/TemplateModule/;
