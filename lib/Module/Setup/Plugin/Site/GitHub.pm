package Module::Setup::Plugin::Site::GitHub;
use strict;
use warnings;
use base 'Module::Setup::Plugin';
use JSON;
use LWP::UserAgent;

sub register {
    my($self, ) = @_;
    $self->add_trigger( before_dump_config       => \&before_dump_config );
    $self->add_trigger( finalize_create_skeleton => \&finalize_create_skeleton );
}

sub before_dump_config {
    my($self, $config) = @_;

    my %modules = (
        readme_from          => 'Module::Install::ReadmeFromPod',
        readme_markdown_from => 'Module::Install::ReadmeMarkdownFromPod',
        readme_pod_from      => 'Module::Install::ReadmePodFromPod',
        githubmeta           => 'Module::Install::GithubMeta',
    );

    while (my($name, $module) = each %modules) {
        my $version = eval "require $module; 'installed '.\$$module\::VERSION;" || 'not installed';
        $config->{$name} = 0;
        if ($self->dialog("use $name? (depend $module, $version [Yn] ", 'y') =~ /[Yy]/) {
            $config->{$name} = 1;
        }
    }

    $config->{github_format} ||= 'p5-%s';
    $config->{github_format} = $self->dialog("github repository name format: ", $config->{github_format});
}

# run github developer api
sub finalize_create_skeleton {
    my $self = shift;
    my $user  = $self->shell('git config --get github.user');
    chomp $user;
    my $token = $self->shell('git config --get github.token');
    chomp $token;
    unless ($user && $token) {
        $self->log("set the github.token And github.user for git config if you wants the create github repository.");
        return;
    }

    if ($self->dialog("create GitHub repository? [Yn] ", 'y') =~ /[Yy]/) {
        # create repository
        my $name = sprintf $self->config->{github_format}, $self->distribute->dist_name;
        $name = $self->dialog("github repository name: ", $name);

        my $description = 'Perl Module of ' . $self->distribute->module;
        $description = $self->dialog("github repository description: ", $description);

        my $homepage = '';
        $homepage = $self->dialog("github repository homepage: ", $homepage);

        my $public = 1;
        if ($self->dialog("create private repository? [yN] ", 'n') =~ /[Yy]/) {
            $public = 0;
        }

        unless (_create_repository(
            login       => $user,
            token       => $token,
            name        => $name,
            description => $description,
            homepage    => $homepage,
            public      => $public,
        )) {
            $self->log('can not created on GitHub');
            return;
        }

        if ($self->dialog("try git push to GitHub? [Yn] ", 'y') =~ /[Yy]/) {
            !$self->system('perl', 'Makefile.PL') or die $?;
            !$self->system('make', 'test')        or die $?;
            !$self->system('make', 'distclean')   or die $?;
            unless (-d '.git') {
                !$self->system('git', 'init')                           or die $?;
                !$self->system('git', 'add', '.')                       or die $?;
                !$self->system('git', 'commit', '-m', 'initial commit') or die $?;
            }
            !$self->system('git', 'remote', 'add', 'origin', "git\@github.com:${user}/${name}.git") or die $?;
            !$self->system('git', 'push', 'origin', 'master') or die $?;
        }
    }
}

sub _create_repository {
    my %args = @_;
    my $ua = LWP::UserAgent->new(
        agent      => join('/', __PACKAGE__, $Module::Setup::VERSION),
        cookie_jar => +{},
    );
    my $res = $ua->post(
        'https://github.com/api/v2/json/repos/create' => \%args 
    );
    $res->is_success;
}

1;
