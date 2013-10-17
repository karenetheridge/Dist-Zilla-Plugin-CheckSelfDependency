use strict;
use warnings;
package Dist::Zilla::Plugin::CheckSelfDependency;
# ABSTRACT: Check if your distribution declares a dependency on itself
# vim: set ts=8 sw=4 tw=78 et :

use Moose;
with 'Dist::Zilla::Role::AfterBuild';
use List::MoreUtils qw(any uniq);
use Module::Metadata;
use namespace::autoclean;

sub after_build
{
    my $self = shift;

    my $prereqs = $self->zilla->prereqs->as_string_hash;

    # for now, we check all phases and types.
    my @prereqs = uniq
        map { keys %$_ }
        map { values %$_ }
        grep { defined }
        @{$prereqs}{qw(configure build runtime test)};

    my $files = $self->zilla->find_files(':InstallModules');

    my @errors;
    foreach my $file (@$files)
    {
        my @packages = Module::Metadata->new_from_file($file->name)->packages_inside;
        foreach my $prereq (@prereqs)
        {
            push @errors, $prereq . ' is listed as a prereq, but is also provided by this dist ('
                    . $file->name . ')!'
                if any { $prereq eq $_ } @packages;
        }
    }

    $self->log_fatal(@errors) if @errors;
}

__PACKAGE__->meta->make_immutable;
__END__

=pod

=for Pod::Coverage after_build

=head1 SYNOPSIS

In your F<dist.ini>:

    [CheckSelfDependency]

=head1 DESCRIPTION

This is a L<Dist::Zilla> plugin that runs in the I<after build> phase, which
checks all of your module prerequisites (all phases, all types except develop) to confirm
that none of them refer to modules that are provided by this distribution.

While some prereq providers (e.g. L<C<[AutoPrereqs]>|Dist::Zilla::Plugin::AutoPrereqs>)
do not inject dependencies found internally, there are many plugins that
generate code and also inject the prerequisites needed by that code, without
regard to whether some of those modules might be provided by your dist.

If such modules are found, the build fails.  To remedy the situation, remove
the plugin that adds the prerequisite, or remove the prerequisite itself with
L<C<[RemovePrereqs]>|Dist::Zilla::Plugin::RemovePrereqs>. (Remember that
plugin order is significant -- you need to remove the prereq after it has been
added.)

=head1 SUPPORT

=for stopwords irc

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-CheckSelfDependency>
(or L<bug-Dist-Zilla-Plugin-CheckSelfDependency@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-CheckSelfDependency@rt.cpan.org>).
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=cut
