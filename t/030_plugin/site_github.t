use Module::Setup::Test::Utils;
use Test::More;

system 'git', '--version';
plan skip_all => "git is not installed." if $?;
use Test::Requires qw( JSON LWP::UserAgent );
use Module::Setup::Plugin::Site::GitHub;

plan tests => 11;

module_setup { init => 1 };

dialog {
    my($self, $msg, $default) = @_;
    if ($msg =~ /github/) {
        return $default;
    }
    return 'n' if $msg =~ /create private repository/;
    return $msg =~ /GitHub/ ? 'y' : 'n';
};

no warnings 'redefine';
my @systems = (
    ['perl', 'Makefile.PL'],
    ['make', 'test'],
    ['make', 'distclean'],
    ['git', 'init'],
    ['git', 'add', '.'],
    ['git', 'commit', '-m', 'initial commit'],
    ['git', 'remote', 'add', 'origin', "git\@github.com:user/p5-Site-GitHub0.git"],
    ['git', 'push', 'origin', 'master'],
);
local *Module::Setup::system = sub {
    my($self, @args) = @_;
    is_deeply(\@args, shift(@systems));
    return 0;
};
my @shell_res = qw( user token );
my @shells = (
    'git config --get github.user',
    'git config --get github.token',
);
local *Module::Setup::shell = sub {
    my($self, $shell) = @_;
    my $cmd = shift @shells;
    is($shell, $cmd, $cmd);
    shift @shell_res;
};

local *Module::Setup::Plugin::Site::GitHub::_create_repository = sub {
    my %args = @_;
    is_deeply(\%args, {
        'homepage'    => '',
        'public'      => 1,
        'name'        => 'p5-Site-GitHub0',
        'description' => 'Perl Module of Site::GitHub0',
        'token'       => 'token',
        'login'       => 'user',
    }, 'create repository params');
};

module_setup { target => 1, plugins => ['Site::GitHub'], github_format => 'p5-%s' }, 'Site::GitHub0';
