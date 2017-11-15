package Moxie::Enum;
# ABSTRACT: Yet Another Enum Generator

use v5.22;
use warnings;
use experimental qw[
    signatures
    postderef
];

use Scalar::Util ();
use BEGIN::Lift  ();

our $VERSION   = '0.07';
our $AUTHORITY = 'cpan:STEVAN';

# ...

our %PACKAGE_TO_ENUM;

sub import ($class) {
    # get the caller ...
    my $caller = caller;
    # and call import_into ...
    $class->import_into( $caller );
}

sub import_into ($class, $caller) {
    BEGIN::Lift::install(
        ($caller, 'enum') => sub ($type, @args) {
            my %enum;
            if ( scalar @args == 1 && ref $args[0] eq 'HASH' ) {
                %enum = $args[0]->%*;
            }
            else {
                my $idx = 0;
                %enum = map { $_ => ++$idx } @args;
            }

            foreach my $key ( keys %enum ) {
                no strict 'refs';
                $enum{ $key } = Scalar::Util::dualvar( $enum{ $key }, $key );
                *{$caller.'::'.$key} = sub (@) { $enum{ $key } };
            }

            $PACKAGE_TO_ENUM{ $caller } //= {};
            $PACKAGE_TO_ENUM{ $caller }->{ $type } = \%enum;

            return;
        }
    );
}

## ...

sub get_enum_for ($pkg, $type) {
    return unless exists $PACKAGE_TO_ENUM{ $pkg }
               && exists $PACKAGE_TO_ENUM{ $pkg }->{ $type };
    return $PACKAGE_TO_ENUM{ $pkg }->{ $type }->%*;
}

sub get_value_for ($pkg, $type, $name) {
    my %enum = get_enum_for( $pkg, $type );
    return $enum{ $name };
}

sub has_value_for ($pkg, $type, $name) {
    my %enum = get_enum_for( $pkg, $type );
    return exists $enum{ $name };
}

sub get_keys_for   ($pkg, $type) { my %enum = get_enum_for( $pkg, $type ); keys   %enum }
sub get_values_for ($pkg, $type) { my %enum = get_enum_for( $pkg, $type ); values %enum }

1;

__END__

=pod

=head1 DESCRIPTION

This provides a simple enumeration type for use with
Moxie classes.

=cut
