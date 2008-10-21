package Module::Setup;

use strict;
use warnings;
use 5.008001;
our $VERSION = '0.04';

use Carp ();
use Class::Trigger;
use Cwd ();
use ExtUtils::MakeMaker qw(prompt);
use File::HomeDir;
use File::Path;
use File::Temp;
use Getopt::Long;
use Path::Class;
use Pod::Usage;

use Module::Setup::Distribute;
use Module::Setup::Path;

our $HAS_TERM;

sub argv       { shift->{argv} }
sub config     { shift->{config} }
sub options    { shift->{options} }
sub base_dir   { shift->{base_dir} }
sub distribute { shift->{distribute} }

sub new {
    my($class, %args) = @_;

    $args{options} ||= +{};
    $args{argv}    ||= +[];
    $args{_current_dir} = Cwd::getcwd;

    bless { %args }, $class;
}

sub DESTROY {
    my $self = shift;
    chdir $self->{_current_dir} unless $self->{_current_dir} eq Cwd::getcwd;
}

sub _setup_options_pod2usage {
    pod2usage(1);
}
sub _setup_options_version {
    print "module-setup v$VERSION\n";
    exit 1;
}

sub setup_options {
    my($self, %args) = @_;
    $Module::Setup::HAS_TERM = 1;

    _setup_options_pod2usage unless @ARGV;

    my $options = {};
    GetOptions(
        'init'                         => \($options->{init}),
        'pack'                         => \($options->{pack}),
        'direct'                       => \($options->{direct}),
        'flavor|flavour=s'             => \($options->{flavor}),
        'flavor-class|flavour-class=s' => \($options->{flavor_class}),
        'plugin=s@'                    => \($options->{plugins}),
        'target'                       => \($options->{target}),
        'module-setup-dir'             => \($options->{module_setup_dir}),
        version                        => \&_setup_options_version,
        help                           => \&_setup_options_pod2usage,
    ) or _setup_options_pod2usage;

    $self->{options} = $options;
    $self->{argv}    = \@ARGV;
    $self;
}


sub _clear_triggers {
    my $self = shift;
    # reset triggers # this is bad hack
    delete $self->{__triggers};
    delete $self->{_class_trigger_results};
}

sub _load_argv {
    my($self, $name, $default) = @_;

    $self->options->{$name} = @{ $self->argv } ? shift @{ $self->argv } : undef;
    if (!$self->options->{$name} && defined $default) {
        $self->options->{$name} = ref($default) eq 'CODE' ? $default->() : $default;
    }
    $self->options->{$name};
}

sub setup_base_dir {
    my $self = shift;

    my $path;
    if ($self->options->{direct}) {
        $path = File::Temp->newdir;
    } else {
        $path = $self->options->{module_setup_dir} || $ENV{MODULE_SETUP_DIR} || Path::Class::Dir->new(File::HomeDir->my_home, '.module-setup');
    }
    die 'module_setup directory was not able to be discovered.' unless $path;

    $self->{base_dir} = Module::Setup::Path->new($path);
    $self->base_dir->init_directories unless $self->base_dir->is_initialized;
}

sub run {
    my $self    = shift;
    my $options = $self->options;
    $self->_clear_triggers;

    $options->{flavor_class} ||= 'Default';
    $self->setup_base_dir;

    if ($options->{init}) {
        $self->_load_argv( flavor => 'default' );
        return $self->create_flavor;
    }

    $self->_load_argv( module => '' );
    $self->_load_argv( flavor => sub { $self->select_flavor } );
    $self->base_dir->set_flavor($options->{flavor});

    Carp::croak "flavor name is required" unless $options->{flavor};
    Carp::croak "module name is required" unless $options->{module};

    return $self->pack_flavor if $options->{pack};

    $self->create_flavor unless $self->base_dir->flavor->is_dir;

    $self->load_config;
    $self->load_plugins;

    # create skeleton
    $self->create_skeleton;
    $self->call_trigger( 'after_create_skeleton' );

    # test
    chdir $self->distribute->dist_path;
    $self->call_trigger( 'check_skeleton_directory' );
    $self->call_trigger( 'finalize_create_skeleton' );
    chdir $self->{_current_dir};
}


sub load_config {
    my $self = shift;
    my $options = $self->options;

    my $option_plugins = delete $options->{plugins} || [];
    my $config = $self->base_dir->flavor->config->load;
    $config = +{
        plugins => [],
        %{ $config },
        %{ $options },
    };
    push @{ $config->{plugins} }, @{ $option_plugins };

    $self->{config} = $config;
}

sub plugin_collect {
    my $self = shift;

    my %loaded_local_plugin;
    for my $local_plugin ( $self->base_dir->global_plugins->collect, $self->base_dir->flavor->plugins->collect ) {
        $local_plugin->require;
        if ($local_plugin->package->isa('Module::Setup::Plugin')) {
            $loaded_local_plugin{$local_plugin->package} = $local_plugin;
        }
    }
    %loaded_local_plugin;
}

sub load_plugins {
    my $self = shift;

    my %loaded_local_plugin = $self->plugin_collect;

    $self->{loaded_plugin} ||= +{};
    for my $plugin (@{ $self->config->{plugins} }) {
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
            eval "require $pkg"; ## no critic
            Carp::croak $@ if $@;
        }
        $self->{loaded_plugin}->{$pkg} = $pkg->new( context => $self, config => $config );
    }
}

sub write_file {
    my($self, $opts) = @_;
    my $path = $opts->{dist_path};

    if (-e $path) {
        my $ans = $self->dialog("$path exists. Override? [yN] ", 'n');
        return if $ans !~ /[Yy]/;
    } else {
        $path->dir->mkpath;
    }

    $self->log("Creating $path");
    my $out = $path->openw;
    $out->print($opts->{template});
    $out->close;

    chmod oct($opts->{chmod}), $path if $opts->{chmod};
}

sub install_flavor {
    my($self, $tmpl) = @_;

    my $flavor = $self->base_dir->flavor;
    my $path;
    if (exists $tmpl->{file} && $tmpl->{file}) {
        $path = $flavor->template->path_to(split '/', $tmpl->{file});
    } elsif (exists $tmpl->{dir} && $tmpl->{dir}) {
        return Module::Setup::Path::Dir->new( $flavor->template->path, split('/', $tmpl->{dir}) )->mkpath;
    } elsif (exists $tmpl->{plugin} && $tmpl->{plugin}) {
        $path = $flavor->plugins->path_to(split '/', $tmpl->{plugin});
    } else {
        return;
    }

    $self->write_file(+{
        dist_path => $path,
        %{ $tmpl },
    });
}

sub _load_flavor_class {
    my($self, $class) = @_;
    $class = "Module::Setup::Flavor::$class" unless $class =~ s/^\+//;
    eval " require $class "; Carp::croak $@ if $@; ## no critic
    $class;
}

sub create_flavor {
    my $self = shift;

    my $options = $self->options;
    my $name    = $options->{flavor};
    my $flavor_class = $self->_load_flavor_class($options->{flavor_class});

    $self->base_dir->set_flavor($name);
    Carp::croak "create flavor: $name exists " if $self->base_dir->flavor->is_exists;

    my @template = $flavor_class->loader;
    my $config = +{};
    for my $tmpl (@template) {
        if (exists $tmpl->{config} && ref($tmpl->{config}) eq 'HASH') {
            $config = $tmpl->{config};
        } else {
            $self->install_flavor($tmpl);
        }
    }

    $self->base_dir->flavor->plugins->path->mkpath;
    $self->base_dir->flavor->template->path->mkpath;

    if (exists $options->{plugins} && $options->{plugins} && @{ $options->{plugins} }) {
        $config->{plugins} ||= [];
        push @{ $config->{plugins} }, @{ delete $options->{plugins} };
    }
    $config->{plugins} ||= [];

    # load plugins
    local $self->{config} = +{
        %{ $config },
        %{ $options },
        plugins => $config->{plugins},
    };
    $self->load_plugins;

    $self->call_trigger( befor_dump_config => $config );

    $self->_clear_triggers;

    $self->base_dir->flavor->config->dump($config);
}

sub create_skeleton {
    my $self   = shift;
    my $config = $self->config;

    $self->{distribute} = Module::Setup::Distribute->new(
        $config->{module},
        target => $config->{target},
    );
    $self->call_trigger( 'after_setup_module_attribute' );
    $self->distribute->dist_path->mkpath;

    my $template_vars = {
        module      => $self->distribute->module,
        dist        => $self->distribute->dist_name,
        module_path => $self->distribute->module_path,
        config      => $config,
        localtime   => scalar localtime,
    };
    $self->call_trigger( after_setup_template_vars => $template_vars);
    $self->{distribute}->set_template_vars($template_vars);

    for my $path ($self->base_dir->flavor->template->find_files) {
        $self->{distribute}->install_template($self, $path);
    }
    $self->call_trigger( 'append_template_file' );

    return $template_vars;
}

sub _collect_flavor_files {
    my($self, $template, $path_name, $type) = @_;

    my $base_path = $type->path;
    for my $file ($type->find_files) {
        my @path = $file->is_dir ? $file->dir_list : ($file->dir->dir_list, $file->basename);
        while ($path[0] eq '.') { shift @path };

        if ($file->is_dir) {
            push @{ $template }, +{
                dir => join('/', @path),
            };
        } else {
            my $body = $type->path_to($file)->slurp;
            push @{ $template }, +{
                $path_name => join('/', @path),
                template   => $body,
            };
        }
    }
}

sub pack_flavor {
    my $self = shift;
    my $config = $self->options;
    my $module = $config->{module};
    my $flavor = $config->{flavor};

    my $template = [];
    $self->_collect_flavor_files($template, file   => $self->base_dir->flavor->template);
    $self->_collect_flavor_files($template, plugin => $self->base_dir->flavor->plugins);
    push @{ $template }, +{
        config => YAML::LoadFile($self->base_dir->flavor->config->path),
    };

    my $eq = '=';
    my $yaml = YAML::Dump(@{ $template });
    $self->stdout(<<FLAVOR__);
package $module;
use strict;
use warnings;
use base 'Module::Setup::Flavor';
1;

${eq}head1

$module - pack from $flavor

${eq}head1 SYNOPSIS

  $ module-setup --init --flavor-class=+$module new_flavor

${eq}cut

\__DATA__

$yaml
FLAVOR__
}

sub select_flavor {
    my $self = shift;
    return 'default' if $self->options->{direct};
    return 'default' if $self->base_dir->flavors->path->children == 0;

    my @flavors;
    for my $flavor ( $self->base_dir->flavors->path->children ) {
        next unless $flavor->is_dir;
        my $name = $flavor->dir_list(-1);
        ($name eq 'default') ? unshift @flavors, $name :  push @flavors, $name;
    }
    return $flavors[0] if @flavors == 1;

    my $num = 1;
    my $message;
    for my $flavor (@flavors) {
        $message .= sprintf "[%d]: %s\n", $num++, $flavor;
    }

    my $selected;
    $self->dialog( "${message}Select flavor:", 1, sub {
        my($self, $ret) = @_;
        return unless $ret =~ /^[0-9]+$/;
        $selected = $flavors[ $ret - 1 ];
    } );
    $self->log("You chose flavor: $selected");
    return $selected;
}

sub stdout {
    my($self, $msg) = @_;
    print STDOUT "$msg\n" if $HAS_TERM;
}
sub log {
    my($self, $msg) = @_;
    print STDERR "$msg\n" if $HAS_TERM;
}
sub dialog {
    my($self, $msg, $default, $validator_callback) = @_;
    return $default unless $HAS_TERM;
    while (1) {
        my $ret = prompt($msg, $default);
        return $ret unless $validator_callback && ref($validator_callback) eq 'CODE';
        return $ret if $validator_callback->($self, $ret);
    }
}

sub system {
    my($self, @args) = @_;
    CORE::system(@args);
}

1;
__END__

=head1 NAME

Module::Setup - a simple module maker "yet another Module::Start(?:er)?"

=head1 SYNOPSIS

simply use

  $ module-setup Foo::Bar

make flavor

  $ module-setup --init catalyst-action # create a "catalyst actions" flavor

edit for flavor

  $ cd ~/.module-setup/flavor/catalyst-action/template && some files edit for catalyst action templates

use flavor

  $ module-setup Foo catalyst-action # create to Catalyst::Action::Foo module

redistribute pack for flavor

  $ module-setup --pack MyFlavorCatalystAction catalyst-action > MyFlavorCatalystAction.pm

using redistributed flavor

  $ module-setup --direct --flavor-class=+MyFlavorCatalystAction New::Class

importing redistributed flavor

  $ module-setup --init --flavor-class=+MyFlavorCatalystAction new_flavor

for git

  $ module-setup --plugin=VC::Git Foo::Bar # or edit your ~/.module-setup/flavor/foo/config.yaml


=head1 DESCRIPTION

Module::Setup is very simply module start kit.

When the module-setup command is executed first, a necessary template for ~/.module-setup directory is copied.

=head1 What's difference Module::Setup and Module::Starter?

L<Module::Starter> is very useful module. However customize of module template is complex.

If L<Module::Starter::PBP> is used, do you solve it?

Yes, but switch of two or more templates is complex.

If Module::Setup is used, switch of template flavor is easy.

flavor customized uniquely becomes the form which can be redistributed by "module-setup --pack".

if incorporating Module::Setup in your application, you can make Helper which is well alike of Catalyst::Helper.

=head1 Example For Incorporating

  use Module::Setup;
  my $pmsetup = Module::Setup->new;
  local $ENV{MODULE_SETUP_DIR} = '/tmp/module-setup'; # dont use  ~/.module-setup directory
  my $options = {
      # see setup_options method
  };
  $pmsetup->run($options, [qw/ New::Module foo_flavor /]); # create New::Module module with foo_flavor flavor

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

walf443

hidek

=head1 SEE ALSO

L<Module::Setup::Plugin>, L<module-setup>

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
