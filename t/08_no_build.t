use strict;
use warnings;

use Test::More 0.88;
use Test::Needs 'Moo';
use Test::Fatal;
use Test::Moose 'with_immutable';
use Test::Deep;

{
    package Parent;
    use Moose;
    use MooseX::SlurpyConstructor;
    has slurpy => (
        is      => 'ro', isa => 'HashRef[Str]',
        slurpy  => 1,
        default => sub { {} },
    );
}

{
    package Child;
    use Moo;
    extends 'Parent';
}

with_immutable {
    my $obj;
    is(
        exception { $obj = Child->new },
        undef,
        'no errors when instantiating a Moo child of a slurpy superclass',
    );

    cmp_deeply(
        $obj->slurpy,
        {},
        'no constructor arguments were slurped up',
    );

} 'Parent';

done_testing;
