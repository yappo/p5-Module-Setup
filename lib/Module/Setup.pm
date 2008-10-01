package Module::Setup;

use strict;
use warnings;
our $VERSION = '0.01';

use Carp ();
use Class::Trigger;
use ExtUtils::MakeMaker qw(prompt);
use Fcntl qw( :mode );
use File::Basename;
use File::Find::Rule;
use File::Path;
use File::Spec;
use File::Temp;
use Getopt::Long;
use Module::Collect;
use Pod::Usage;
use YAML ();


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
    my($self, $options, $argv) = @_;

    my $set_has_term = 0;
    if (defined $options && ref($options) eq 'HASH') {
        $set_has_term = 1 unless $options->{unset_hash_term};
    } else { 
        $set_has_term = 1;
        $options  = $self->setup_options;
    }
    no warnings 'redefine';
    local *has_term = $self->set_has_term_sub if !$set_has_term;

    my @argv = defined $argv && ref($argv) eq 'ARRAY' ? @{ $argv } : @ARGV;

    # create flavor
    if ($options->{init}) {
        $options->{flavor} = shift @argv if @argv;
        return $self->create_flavor($options);
    }

    # create module
    $options->{module} = shift @argv;
    $options->{flavor} = shift @argv if @argv;

    if ($options->{pack}) {
        #pack flavor template
        return $self->pack_flavor($options);
    }

    local $ENV{MODULE_SETUP_DIR} = File::Temp->newdir if $options->{direct};

    unless ( -d $self->module_setup_dir('flavors') && -d $self->module_setup_dir('flavors', $options->{flavor}) ) {
        # setup the module-setup directory
        $self->create_flavor($options);
        $self->_create_directory( dir => $self->module_setup_dir('plugins') );
    }

    my $config = $self->load_config($options);
    $self->load_plugins($config);

    # create skeleton
    my $chdir = $self->create_skeleton($config);
    return unless $chdir;

    # test
    chdir $chdir;
    $self->call_trigger('check_skeleton_directory');
}

sub setup_options {
    my $self = shift;

    pod2usage(2) unless @ARGV;

    my $options = {};
    GetOptions(
        'init'           => \($options->{init}),
        'pack'           => \($options->{pack}),
        'direct'         => \($options->{direct}),
        'flavor=s'       => \($options->{flavor}),
        'flavor-class=s' => \($options->{flavor_class}),
        'plugin=s@'      => \($options->{plugins}),
        version          => sub {
            print "module-setup v$VERSION\n";
            exit 1;
        },
        help             => sub { pod2usage(1); },
    ) or pod2usage(2);

    $options->{flavor}       ||= 'default';
    $options->{flavor_class} ||= 'Default';
    $options;
}

sub load_config {
    my($self, $options) = @_;

    $options->{plugins} ||= [];
    my @option_plugins = @{ delete $options->{plugins} };

    my $config = YAML::LoadFile( $self->module_setup_dir('flavors', $options->{flavor}, 'config.yaml') );
        $config = +{
        %{ $config },
        %{ $options },
    };

    $config->{plugins} ||= [];
    push @{ $config->{plugins} }, @option_plugins;

    $config;
}

sub plugin_collect {
    my($self, $config) = @_;

    my @local_plugins;
    push @local_plugins, @{ Module::Collect->new( path => $self->module_setup_dir('plugins') )->modules };
    push @local_plugins, @{ Module::Collect->new( path => $self->module_setup_dir('flavors', $config->{flavor}, 'plugins') )->modules };
    my %loaded_local_plugin;;
    for my $local_plugin (@local_plugins) {
        $local_plugin->require;
        if ($local_plugin->package->isa('Module::Setup::Plugin')) {
            $loaded_local_plugin{$local_plugin->package} = $local_plugin;
        }
    }
    %loaded_local_plugin;
}

sub load_plugins {
    my($self, $config) = @_;

    my %loaded_local_plugin = $self->plugin_collect($config);

    my %loaded_plugin;
    for my $plugin (@{ $config->{plugins} }) {
        my $pkg;
        my $config = +{};
        if (ref($plugin)) {
            if (ref($plugin) eq 'HASH') {
                $pkg    = $plugin->{module};
                $config = $plugin->{config};
            } else {
                next;
            }
        } else {
            $pkg = $plugin;
        }
        $pkg = "Module::Setup::Plugin::$pkg" unless $pkg =~ s/^\+//;

        unless ($loaded_local_plugin{$pkg}) {
            eval "require $pkg";
            Carp::croak $@ if $@;
        }
        $loaded_plugin{$pkg} = $pkg->new( context => $self, config => $config );
    }
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
    my($self, $opts) = @_;
    my $path = $opts->{dist_path};

    if (-e $path) {
        my $ans = $self->dialog("$path exists. Override? [yN] ", 'n');
        return if $ans !~ /[Yy]/;
    }

    $self->_create_directory( file => $path );

    $self->log("Creating $path");
    open my $out, ">", $path or die "$path: $!";
    print $out $opts->{template};
    close $out;

    chmod oct($opts->{chmod}), $path if $opts->{chmod};
}

sub install_flavor {
    my($self, $name, $tmpl) = @_;

    my $path = (exists $tmpl->{plugin} && $tmpl->{plugin}) ?
        $self->module_setup_dir( 'flavors', $name, 'plugins', $tmpl->{plugin} ) :
            $self->module_setup_dir( 'flavors', $name, 'template', $tmpl->{file} );
    $self->write_file(+{
        dist_path => $path,
        %{ $tmpl },
    });
}

sub install_template {
    my($self, $base, $path, $vars, $module_attribute) = @_;

    my $src  = File::Spec->catfile($base, $path);
    my $dist = File::Spec->catfile(@{ $module_attribute->{dist_path} }, $path);
    return $self->create_directory( dir => $dist ) if -d $src;

    my $mode = ( stat $src )[2];
    $mode = sprintf "%03o", S_IMODE($mode);

    open my $fh, '<', $src or die "$src: $!";
    my $template = do { local $/; <$fh> };
    close $fh;

    my $opts = {
        dist_path => $dist,
        template  => $template,
        chmod     => $mode,
        vars      => $vars,
        content   => undef,
    };
    $self->call_trigger( template_process => $opts );
    $opts->{template} = delete $opts->{content} unless $opts->{template};

    $opts->{dist_path} =~ s/____var-(.+)-var____/$vars->{$1} || $vars->{config}->{$1}/eg;

    $self->write_file($opts);
}

sub create_flavor {
    my($self, $options) = @_;
    $options ||= +{};
    my $name  = $options->{flavor};
    my $class = $options->{flavor_class};

    $class = "Module::Setup::Flavor::$class" unless $class =~ s/^\+//;

    Carp::croak "create flavor: $name exists " if -d $self->module_setup_dir('flavors', $name);
    eval " require $class "; Carp::croak $@ if $@;

    my @template = $class->loader;
    my $config = +{};
    for my $tmpl (@template) {
        if (exists $tmpl->{config} && ref($tmpl->{config}) eq 'HASH') {
            $config = $tmpl->{config};
        } else {
            $self->install_flavor($name, $tmpl);
        }
    }

    # plugins
    $self->_create_directory( dir => $self->module_setup_dir('flavors', $name, 'plugins') );

    if (exists $options->{plugins} && $options->{plugins} && @{ $options->{plugins} }) {
        $config->{plugins} ||= [];
        push @{ $config->{plugins} }, @{ $options->{plugins} };
    }
    $config->{plugins} ||= [];

    # load plugins
    $self->load_plugins(+{
        %{ $config },
        %{ $options },
        plugins => $config->{plugins},
    });

    # ask author and mail
    $config->{author} ||= 'Default Name';
    $config->{author} = $self->dialog("Your name: ", $config->{author});

    $config->{email} ||= 'default {at} example.com';
    $config->{email} = $self->dialog("Your email: ", $config->{email});

    $self->call_trigger( befor_dump_config => $config );

    # reset triggers # this is bad hack
    delete $self->{__triggers};
    delete $self->{_class_trigger_results};

    # save config
    YAML::DumpFile($self->module_setup_dir('flavors', $name, 'config.yaml'), $config);
}

sub _find_flavor_template {
    my($self, $config) = @_;
    my $module = $config->{module};
    my $flavor = $config->{flavor};

    Carp::croak "module name is required" unless $module;

    my $flavor_path = $self->module_setup_dir('flavors', $flavor);
    Carp::croak "No such flavor: $flavor" unless -d $flavor_path;

    my @files = File::Find::Rule->new->file->relative->in( $self->module_setup_dir('flavors', $flavor, 'template') );
    Carp::croak "No such flavor template files: $flavor" unless @files;
    @files;
}

sub create_skeleton {
    my($self, $config) = @_;
    $config ||= +{};

    my @files = $self->_find_flavor_template($config);

    my $module = $config->{module};
    my $flavor = $config->{flavor};

    my @pkg  = split /::/, $module;
    my $module_attribute = +{
        module    => $module,
        package   => \@pkg,
        dist_name => join('-', @pkg),
        dist_path => [ join('-', @pkg) ],
    };
    $self->call_trigger( after_setup_module_attribute => $module_attribute);

    $self->create_directory( dir => $module_attribute->{dist_name} );

    my $template_vars = {
        module      => $module_attribute->{module},
        dist        => $module_attribute->{dist_name},
        module_path => join('/', @{ $module_attribute->{package} }),
        config      => $config,
        localtime   => scalar localtime,
    };
    $self->call_trigger( after_setup_template_vars => $module_attribute);

    my $base = $self->module_setup_dir('flavors', $flavor, 'template');
    for my $path (@files) {
        $self->install_template($base, $path, $template_vars, $module_attribute);
    }

    File::Spec->catfile( @{ $module_attribute->{dist_path} } );
}

sub pack_flavor {
    my($self, $config) = @_;
    my $module = $config->{module};
    my $flavor = $config->{flavor};

    my @template_files = $self->_find_flavor_template($config);

    my @plugin_files = File::Find::Rule->new->file->relative->in( $self->module_setup_dir('flavors', $flavor, 'plugins') );

    my @template;
    for my $conf (
        { type => 'template', files => \@template_files },
        { type => 'plugins' , files => \@plugin_files },
        { type => 'config'  , files =>['config.yaml'] },
    ) {
        my $base_path;
        if ($conf->{type} eq 'config') {
            $base_path = $self->module_setup_dir('flavors', $flavor);
        } else {
            $base_path = $self->module_setup_dir('flavors', $flavor, $conf->{type});
        }

        for my $file (@{ $conf->{files} }) {
            my $path = File::Spec->catfile($base_path, $file);

            if ($conf->{type} eq 'config') {
                my $data = YAML::LoadFile($path);
                push @template, +{
                    config => $data
                };
            } else {
                open my $fh, '<', $path or die "$path: $!";
                my $data = do { local $/; <$fh> };
                close $fh;
                my $path_name = $conf->{type} eq 'template' ? 'file' : 'plugin';
                push @template, +{
                    $path_name => $file,
                    template   => $data,
                };
            }
        }
    }

    my $yaml = YAML::Dump(@template);
    print <<END;
package $module;
use strict;
use warnings;
use base 'Module::Setup::Flavor';
1;

=head1

$module - pack from $flavor

=head1 SYNOPSIS

  $ module-setup --init --flavor-class=+$module new_flavor

=cut

__DATA__

$yaml
END
}

1;
__END__

=head1 NAME

Module::Setup - a simple module maker "yet another Module::Start(?:er)?"

=head1 SYNOPSIS

  $ module-setup Foo::Bar

  $ module-setup --init catalyst-action # create a "catalyst actions" flavor

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
