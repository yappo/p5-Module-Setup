package Module::Setup::Devel;
use strict;
use warnings;

use Scalar::Util qw(weaken);
use YAML ();

use Module::Setup::Distribute;

use Module::Setup::Path::Flavor;

sub new {
    my($class, $context) = @_;
    my $self = bless { context => $context }, $class;
    weaken $self->{context};
    $self;
}
sub context { shift->{context} }

sub run {
    my $self = shift;

    return $self->test if $self->context->options->{test};
    return $self->pack if $self->context->options->{pack};

    $self->create_skeleton;
}

sub create_skeleton {
    my $self = shift;

    $self->context->_load_argv( flavor_name => '' );
    Carp::croak "flavor class name is required" unless $self->context->options->{flavor_name};

    my $module = $self->context->options->{flavor_name};
    my @pkg = split /::/, $module;
    my $module_path = join '-', @pkg;
    my $base_dir = Module::Setup::Path::Flavor->new($module_path);

    $base_dir->path->subdir('t')->mkpath;
    $base_dir->template->path->subdir('testdir')->mkpath;
    my $fh = $base_dir->template->path->file('testfile.txt')->openw;
    print $fh "hello! $module";
    close $fh;

    $base_dir->create_flavor(+{
        module_setup_flavor_devel => 1,
        class     => $module,
        plugins => [],
        testdata  => +{
            module => 'MyApp',
            files  => [
                {
                    file  => 'testfile.txt',
                    likes => ['hel+o', $module ],
                },
            ],
            dirs   => ['testdir'],
        },
    });
}

sub load_config {
    my $self = shift;
    my $conf = YAML::LoadFile('config.yaml');
    return unless $conf && ref($conf) eq 'HASH' && $conf->{module_setup_flavor_devel};
    return $conf;
}

# make t/all.t && --pack && prove t/*t 
sub test {
    my $self = shift;

    my $conf = $self->load_config;
    return unless $conf;
    my $distribute = Module::Setup::Distribute->new( $conf->{class}, %{ $self->context->options } );

    my @files;my @file;
    my $test = $conf->{testdata};
    for my $data (@{ $test->{files} }) {
        push @files, $data unless ref $data;
        my $like;
        if (@{ $data->{likes} }) {
            my @likes = map { "qr/$_/" } map { s{/}{\\/}g; $_ } @{ $data->{likes} };
            $like  = join ', ', @likes;
        }
        my $str = "    file '$data->{file}'";
        $str .= " => $like" if $like;
        $str .= ";\n";
        push @file, $str;
    }

    my @dirs;
    for my $data (@{ $test->{dirs} }) {
        push @dirs, $data;
    }

    my $code;
    $code .= sprintf("    files qw( %s );\n", @files) if @files;
    $code .= join "\n", @file if @file;
    $code .= sprintf("    dirs qw( %s );\n", @dirs) if @dirs;

    my $module = 'DevelTestFlavor';
    my $fh   = $distribute->target_path->file('t', 'all.t')->openw;
    print $fh <<TEST__;
use Module::Setup::Test::Flavor;

run_flavor_test {
    default_dialog;
    name '$test->{module}';
    flavor '+$module';
$code};
TEST__
    close $fh;

    # create pack
    {
        no strict 'refs';
        no warnings 'redefine';

        my $pack;
        local *Module::Setup::stdout = sub { $pack = $_[1] };
        $self->pack($module);
        open my $fh, '>', "$module.pm" or die $!;
        print $fh $pack;
        close $fh;
    }

    # prove -v
    system 'prove', '-v';
}

sub pack {
    my $self = shift;

    my $conf = $self->load_config;
    return unless $conf;

    my $class;
    if (@_) {
        $class = shift;
    } else {
        $class = $conf->{class};
    }

    $self->context->options->{flavor_dir} = '.';
    $self->context->options->{flavor}     = $class;
    $self->context->options->{module}     = $class;
    $self->context->pack_flavor;
}

1;

__END__

=head1 NAME

Module::Setup::Devel - for --devel option 

==cut
