use t::Utils;
use Test::More tests => 4;

{
    default_dialog;
    module_setup { target => 1 }, 'Dupe';
    my $fh = target_dir('Dupe')->file('README')->openw;
    print $fh 'rewrite';
    close $fh;
    like target_dir('Dupe')->file('README')->slurp, qr/rewrite/;

    module_setup { target => 1 }, 'Dupe';
    like target_dir('Dupe')->file('README')->slurp, qr/rewrite/;

    my $dialog = 0;
    dialog {
        my($self, $msg, $default) = @_;
        return 'n' if $msg =~ /Check Makefile.PL\?/i;
        return 'n' if $msg =~ /Subversion friendly\?/i;
        return $default unless $msg =~ /exists. Override\?/;
        $dialog = 1;
        'y';
    };
    module_setup { target => 1 }, 'Dupe';
    ok $dialog;
    unlike(target_dir('Dupe')->file('README')->slurp, qr/rewrite/);
}
