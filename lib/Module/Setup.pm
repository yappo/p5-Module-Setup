package Module::Setup;

use strict;
use warnings;
our $VERSION = '0.01';

use Carp ();
use ExtUtils::MakeMaker qw(prompt);
use Fcntl qw( :mode );
use File::Basename;
use File::Find::Rule;
use File::Path;
use File::Spec;
use Getopt::Long;
use Pod::Usage;
use Template;
use YAML ();

use Data::Dumper;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub has_term { 0 }
sub set_has_term_sub { sub { 1 } }
sub unset_has_term_sub { sub { 0 } }
sub log {
    my($self, $msg) = @_;
    print STDERR "$msg\n" if $self->has_term;
}
sub dialog {
    my($self, $msg, $default) = @_;
    return $default unless $self->has_term;
    prompt($msg, $default);    
}

sub run {
    my $self = shift;

    no warnings 'redefine';
    local *has_term = $self->set_has_term_sub;;

    pod2usage(2) unless @ARGV;

    my $options = {};
    GetOptions(
        'flavor=s'       => \($options->{flavor}),
        'flavor-class=s' => \($options->{flavor_class}),
        'plugin=s@'      => \($options->{plugins}),
        version          => sub {
            print "module-setup v$VERSION\n";
            exit 1;
        },
        help             => sub { pod2usage(1); },
    ) or pod2usage(2);

    # load plugin

    $options->{flavor_class} ||= 'Default';

    # create flavor
    if ($options->{flavor}) {
        return $self->create_flavor( $options->{flavor}, $options->{flavor_class}, $options );
    }

    unless ( -d $self->module_setup_dir('flavors') && -d $self->module_setup_dir('flavors', 'default') ) {
        # setup the module-setup directory
        $self->create_flavor( 'default', $options->{flavor_class} );
        $self->_create_directory( dir => $self->module_setup_dir('plugins') );
    }

    # create skeleton
    my $module = shift @ARGV;
    my $flavor = shift @ARGV;
    my $chdir = $self->create_skeleton($module, $flavor, $options);
    return unless $chdir;

    # test 
    chdir $chdir;

    !system "perl Makefile.PL" or die $?;
    !system 'make test' or die $?;
    !system 'make manifest' or die $?;
    !system 'make distclean' or die $?;

}

sub module_setup_dir {
    my($self, @path) = @_;
    my $base = $ENV{MODULE_SETUP_DIR} || do {
        eval { require File::HomeDir };
        my $home = $@ ? $ENV{HOME} : File::HomeDir->my_home;
        File::Spec->catfile( $home, '.module-setup' );
    };

    $base  = File::Spec->catfile( $base, @path ) if @path;
    $base;
}

sub class_data {
    my($self, $class) = @_;
    local $SIG{__WARN__} = sub {};
    local $/;
    eval "package $class; <DATA>";
}

sub create_directory {
    my $self = shift;
    $self->_create_directory(@_);
}
sub _create_directory {
    my($self, %opts) = @_;
    my $dir = $opts{dir} || File::Basename::dirname($opts{file});
    unless (-e $dir) {
        $self->log("Creating directory $dir");
        File::Path::mkpath($dir, 0, 0777);
    }
}

sub write_file {
    my($self, $path, $tmpl) = @_;

    if (-e $path) {
        my $ans = $self->dialog("$path exists. Override? [yN] ", 'n');
        return if $ans !~ /[Yy]/;
    }

    $self->_create_directory( file => $path );

    $self->log("Creating $path");
    open my $out, ">", $path or die "$path: $!";
    print $out $tmpl->{template};
    close $out;

    chmod oct($tmpl->{chmod}), $path if $tmpl->{chmod};
}

sub install_flavor {
    my($self, $name, $tmpl) = @_;

    my $path = (exists $tmpl->{plugin} && $tmpl->{plugin}) ?
        $self->module_setup_dir( 'flavors', $name, 'plugins', $tmpl->{plugin} ) :
            $self->module_setup_dir( 'flavors', $name, 'template', $tmpl->{file} );
    $self->write_file($path, $tmpl);
}

my $TEMPLATE;
sub _template_instance {
    $TEMPLATE ||= Template->new;
}

sub install_template {
    my($self, $base, $path, $vars, $dist_path) = @_;

    my $src  = File::Spec->catfile($base, $path);
    my $dist = File::Spec->catfile(@{ $dist_path }, $path);
    return $self->create_directory( dir => $dist ) if -d $src;

    my $mode = ( stat $src )[2];
    $mode = sprintf "%03o", S_IMODE($mode);

    open my $fh, '<', $src;
    my $template = do { local $/; <$fh> };
    $self->_template_instance->process(\$template, $vars, \my $content);
    close $fh;

    $dist =~ s/____var-(.+)-var____/$vars->{$1} || $vars->{config}->{$1}/eg;

    $self->write_file($dist, +{
        template =>$content,
        chmod    => $mode,
    });
}

sub create_flavor {
    my($self, $name, $class, $options) = @_;
    $options ||= +{};

    $class = "Module::Setup::Flavor::$class" unless $class =~ s/^\+//;

    Carp::croak "create flavor: $name exists " if -d $self->module_setup_dir('flavors', $name);
    eval " require $class "; Carp::croak $@ if $@;

    my $data = $self->class_data($class);
    Carp::croak "flavor template class is invalid: $class" unless $data;

    my @template = YAML::Load(join '', $data);
    my $config = +{};
    for my $tmpl (@template) {
        if (exists $tmpl->{config} && $tmpl->{config}) {
            $config = YAML::Load($tmpl->{config});
        } else {
            $self->install_flavor($name, $tmpl);
        }
    }

    # plugins
    $self->_create_directory( dir => $self->module_setup_dir('flavors', $name, 'plugins') );

    # save config
    YAML::DumpFile($self->module_setup_dir('flavors', $name, 'config.yaml'), $config);
}

sub create_skeleton {
    my($self, $module, $flavor, $options) = @_;
    $options ||= +{};
    $flavor ||= 'default';

    Carp::croak "module name is required" unless $module;

    my $flavor_path = $self->module_setup_dir('flavors', $flavor);
    Carp::croak "No such flavor: $flavor" unless -d $flavor_path;

    my @files = File::Find::Rule->new->relative->in( $self->module_setup_dir('flavors', $flavor, 'template') );
    Carp::croak "No such flavor template files: $flavor" unless @files;

    my $config = YAML::LoadFile( $self->module_setup_dir('flavors', $flavor, 'config.yaml') );
    $config = +{
        %{ $config },
        %{ $options },
    };

    my @pkg  = split /::/, $module;
    my $dist = join "-", @pkg;
    my $vars = +{
        modulepath => join("/", @pkg),
    };

    my $dist_path = [ $dist ];
    $self->create_directory( dir => $dist);
    if ($self->dialog("Subversion friendly? [Yn] ", 'y') =~ /[Yy]/) {
        $self->create_directory( dir => File::Spec->catfile( $dist, $_) ) for (qw/ trunk tags branches /);
        push @{ $dist_path }, 'trunk';
    }

    my $vars = {
        module     => $module,
        dist       => $dist,
        modulepath => join("/", @pkg),
        config     => $config,
        localtime  => scalar localtime,
    };
    my $base = $self->module_setup_dir('flavors', $flavor, 'template');
    for my $path (@files) {
        $self->install_template($base, $path, $vars, $dist_path);
    }

    File::Spec->catfile( @{ $dist_path } );
}

1;
__END__

=head1 NAME

Module::Setup - a simple module maker "yet another Module::Start(?:er)?"

=head1 SYNOPSIS

  $ module-setup Foo::Bar

  $ module-setup --flavor=catalyst-action # create a "catalyst actions" flavor

  $ cd ~/.module-setup/catalyst-action && some files edit for catalyst action templates

  $ module-setup Foo catalyst-action # create to Catalyst::Action::Foo module

=head1 DESCRIPTION

Module::Setup is very simply module start kit.

When the module-setup command is executed first, a necessary template for ~/.module-setup directory is copied.

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

=head1 SEE ALSO

this module's base code is pmsetup written by Tatsuhiko Miyagawa.

some pmsetup scripts are in a L<http://svn.coderepos.org/share/lang/perl/misc/pmsetup>

=head1 REPOSITORY

  svn co http://svn.coderepos.org/share/lang/perl/Module-Setup/trunk Module-Setup

Module::Setup is Subversion repository is hosted at L<http://coderepos.org/share/>.
patches and collaborators are welcome.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
