use strict;
use warnings FATAL => 'all';

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;

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

is(
    exception { $tzil->build },
    undef,
    'build is not aborted',
);

done_testing;
