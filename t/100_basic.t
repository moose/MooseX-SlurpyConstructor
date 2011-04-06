use strict;
use warnings;

use Test::Fatal;
use Test::Moose qw( with_immutable );
use Test::More;
use Test::Deep;

{
    package Standard;

    use Moose;

    has 'thing' => ( is => 'rw' );
}

{
    package Slurpier;

    use Moose;
    use MooseX::SlurpyConstructor;

    has 'thing' => ( is => 'rw' );
    has slurpy => ( is => 'ro', slurpy => 1);
}

{
    package Subclass;

    use Moose;
    use MooseX::SlurpyConstructor;

    extends 'Slurpier';

    has 'size' => ( is => 'rw' );
}

{
    package Tricky;

    use Moose;
    use MooseX::SlurpyConstructor;

    has 'thing' => ( is => 'rw' );
    has slurpy => ( is => 'ro', slurpy => 1);

    sub BUILD {
        my $self   = shift;
        my $params = shift;

        delete $params->{spy};
    }
}

{
    package InitArg;

    use Moose;
    use MooseX::SlurpyConstructor;

    has 'thing' => ( is => 'rw', 'init_arg' => 'other' );
    has 'size'  => ( is => 'rw', 'init_arg' => undef );
    has slurpy => ( is => 'ro', slurpy => 1);
}

my @classes = qw( Standard Slurpier Subclass Tricky InitArg );

with_immutable {
    is(
        exception { Standard->new( thing => 1, bad => 99 ) }, undef,
        'standard Moose class ignores unknown params'
    );

    my $obj;
    is(
        exception { $obj = Slurpier->new( thing => 1, bad => 99 ) },
        undef,
        'slurpy constructor doesn\'t die on unknown params'
    );
    cmp_deeply($obj->slurpy, { bad => 99 }, 'slurpy attr grabs unknown param');

    is(
        exception {
            Subclass->new( thing => 1, size => 'large' ) }, undef,
        'subclass constructor handles unknown attributes correctly'
    );

    is(
        exception { $obj = Subclass->new( thing => 1, bad => 98 ) },
        undef,
        'subclass correctly slurps unknown attribute'
    );
    cmp_deeply($obj->slurpy, { bad => 98 }, 'slurpy attr grabs unknown param');

    is(
        exception { $obj = Tricky->new( thing => 1, spy => 99 ) }, undef,
        'can work around slurpy constructor by deleting params in BUILD()'
    );
    cmp_deeply($obj->slurpy, undef, 'slurpy attr had nothing to grab');

    is(
        exception { $obj = Tricky->new( thing => 1, agent => 99 ) },
        undef,
        'Tricky still grabs unknown params other than spy'
    );
    cmp_deeply($obj->slurpy, { agent => 99 }, 'slurpy attr had nothing to grab');

    is(
        exception { $obj = Subclass->new( thing => 1, bad => 97 ) },
        undef,
        'subclass constructor also grabs unknown params'
    );
    cmp_deeply($obj->slurpy, { bad => 97 }, 'slurpy attr grabs unknown param');

    $obj = InitArg->new( thing => 1 );
    cmp_deeply($obj->slurpy, { thing => 1 }, 'slurpy attr grabs unknown param');

    # XXX consider whether this is the right thing to do
    $obj = InitArg->new( size => 1 );
    cmp_deeply($obj->slurpy, { thing => 1 }, 'slurpy attr grabs attr with undef init_arg');

    is(
        exception { InitArg->new( other => 1 ) }, undef,
        'InitArg works when given proper init_arg'
    );
}
@classes;

done_testing();
