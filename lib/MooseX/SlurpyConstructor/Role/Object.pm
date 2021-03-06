package MooseX::SlurpyConstructor::Role::Object;

our $VERSION = '1.31';

# applied as base_class_roles => [ __PACKAGE__ ], for all Moose versions.
use Moose::Role;

use namespace::autoclean;

after BUILDALL => sub {
    my $self   = shift;
    my $params = shift;

    my %attrs = (
        __INSTANCE__ => 1,
        __no_BUILD__ => 1,
        map  { $_ => 1 }
        grep { defined }
        map  { $_->init_arg } $self->meta->get_all_attributes
    );

    my @extra = sort grep { !$attrs{$_} } keys %{$params};
    return if not @extra;

    my $slurpy_attr = $self->meta->slurpy_attr;

    Moose->throw_error('Found extra construction arguments, but there is no \'slurpy\' attribute present!') if not $slurpy_attr;

    my %slurpy_values;
    @slurpy_values{@extra} = @{$params}{@extra};

    $slurpy_attr->set_value( $self, \%slurpy_values );
};

1;

# ABSTRACT: A role which implements a slurpy constructor for Moose::Object

__END__

=pod

=head1 SYNOPSIS

  Moose::Util::MetaRole::apply_base_class_roles(
      for_class => $caller,
      roles =>
          ['MooseX::SlurpyConstructor::Role::Object'],
  );

=head1 DESCRIPTION

When you use L<MooseX::SlurpyConstructor>, your objects will have this
role applied to them. It provides a method modifier for C<BUILDALL()>
from L<Moose::Object> that saves all unrecognized attributes.

=cut
