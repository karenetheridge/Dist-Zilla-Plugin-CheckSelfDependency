use strict;
use warnings FATAL => 'all';

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;

{
    package inc::Provider;
    use Moose;
    with 'Dist::Zilla::Role::MetaProvider';
    sub metadata
    {
        return {
            provides => {
                'Foo::Bar' => { file => 'lib/Foo/Bar.pm', version => '0' },
            },
        };
    }
}

{
    my $tzil = Builder->from_config(
        { dist_root => 't/does_not_exist' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    'GatherDir',
                    'CheckSelfDependency',
                    [ 'Prereqs / DevelopRequires' => { 'Foo::Bar' => '1.23' } ],
                ),
                path(qw(source lib Foo Bar.pm)) => "package Foo::Bar;\n1;\n",
            },
        },
    );

    like(
        exception { $tzil->build },
        qr{Foo::Bar is listed as a prereq, but is also provided by this dist \(lib/Foo/Bar.pm\)!},
        'build is aborted - develop prereq not listed in "provides"',
    );
}

{
    my $tzil = Builder->from_config(
        { dist_root => 't/does_not_exist' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    'GatherDir',
                    'CheckSelfDependency',
                    [ 'Prereqs / DevelopRequires' => { 'Foo::Bar' => '1.23' } ],
                    [ '=inc::Provider' ],
                ),
                path(qw(source lib Foo Bar.pm)) => "package Foo::Bar;\n1;\n",
            },
        },
    );

    is(
        exception { $tzil->build },
        undef,
        'build is not aborted - develop prereq listed in "provides"',
    );
}

done_testing;
