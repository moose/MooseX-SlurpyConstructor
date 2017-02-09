package MooseX::SlurpyConstructor::Trait::Method::Constructor;

our $VERSION = '1.31';

# applied as class_metaroles => { constructor => [ __PACKAGE__ ] }, for Moose 1.2x

use Moose::Role;

use namespace::autoclean;

use B ();

around '_generate_BUILDALL' => sub {
    my $orig = shift;
    my $self = shift;

    my $source = $self->$orig();
    $source .= ";\n" if $source;

    my @attrs = (
        '__INSTANCE__ => 1,',
        '__no_BUILD__ => 1,',
        map  { B::perlstring($_) . ' => 1,' }
        grep { defined }
        map  { $_->init_arg } @{ $self->_attributes }
    );

    my $slurpy_attr = $self->associated_metaclass->slurpy_attr;

    $source .= join('',
        'my %attrs = (' . ( join ' ', @attrs ) . ');',
        'my @extra = sort grep { !$attrs{$_} } keys %{ $params };',
        'if (@extra){',

        !$slurpy_attr
            ? 'Moose->throw_error("Found extra construction arguments, but there is no \'slurpy\' attribute present!");'
            : (
                'my %slurpy_values;',
                '@slurpy_values{@extra} = @{$params}{@extra};',

                '$instance->meta->slurpy_attr->set_value( $instance, \%slurpy_values );',
            ),
        '}',
    );

    return $source;
};

1;

# ABSTRACT: A role to make immutable constructors slurpy

__END__

=pod

=head1 DESCRIPTION

This role simply wraps C<_generate_BUILDALL()> (from
L<Moose::Meta::Method::Constructor>) so that immutable classes have a
slurpy constructor.

=cut
