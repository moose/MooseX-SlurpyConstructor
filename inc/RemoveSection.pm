use strict;
use warnings;
package inc::RemoveSection;

# Since weaver bundles cannot take arguments, it's not possible to write a
# bundle like [@Filter], or add a -remove feature to an author bundle
# directly. Instead, we need to write a separate weaver plugin that explicitly
# splices out an undesired plugin or section from the configuration.

# We also cannot splice a config right in the object because many section or
# plugin configuration attributes are immutable, and we cannot touch the
# config before the object is instantiated.

# Usage:
# [=inc::RemoveSection]
# ; full package name
# remove = Pod::Weaver::Plugin::SingleEncoding
# ; or moniker assigned from config (remember things from bundles have
# ; the bundle name prepended, e.g. @Default/Authors)
# remove = DESCRIPTION
# ; or shortened name as you'd use it in weaver.ini:
# remove = -H1Nester
# remove = Contributors
#
# it must appear in weaver.ini (or the bundle config) after the plugin(s) or
# section(s) to be removed.

use Moose;
with 'Pod::Weaver::Role::Plugin';
use List::Util 1.45 'any';
use Scalar::Util 'blessed';
use namespace::autoclean;

# TODO move this functionality into Pod::Weaver::Role::PluginRemover.
# and use it from RemovePlugin, RemoveSection.

sub mvp_multivalue_args { 'remove' }

has remove => (
    isa => 'ArrayRef[Str]',
    traits => ['Array'],
    handles => { remove => 'elements' },
    required => 1,
);

sub BUILD
{
    my $self = shift;
    $self->remove_plugins($self->remove);
}

sub _exp { Pod::Weaver::Config::Assembler->expand_package($_[0]) }

sub remove_plugins
{
    my ($self, @remove) = @_;

    my $plugins = $self->weaver->plugins;

    # stolen 99% from @Filter and Dist::Zilla::Role::PluginBundle::PluginRemover
    for my $i (reverse 0 .. $#{$plugins}) {
        if (any(
            sub {
                blessed($plugins->[$i]) eq $_
                    or
                $plugins->[$i]->plugin_name eq $_
                    or
                blessed($plugins->[$i]) eq _exp($_)
            }, @remove))
        {
            $self->log([ 'removing weaver plugin/section: %s', $plugins->[$i]->plugin_name ]);
            splice @$plugins, $i, 1;
        }
    }
}

__PACKAGE__->meta->make_immutable;
1;
