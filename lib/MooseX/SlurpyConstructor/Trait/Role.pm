package MooseX::SlurpyConstructor::Trait::Role;

our $VERSION = '1.31';

use Moose::Role;

sub composition_class_roles { 'MooseX::SlurpyConstructor::Trait::Composite' }

no Moose::Role;

1;
__END__

=pod

=for Pod::Coverage composition_class_roles

=cut
