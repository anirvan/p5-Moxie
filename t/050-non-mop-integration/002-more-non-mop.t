#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
    eval { require Moose; 1 }
        or plan skip_all => "This test requires Moose";
}

{
    package Person;
    BEGIN { $INC{'Person.pm'} = __FILE__ }
    use Moose;

    # NOTE:
    # we have to make these attribute lazy
    # because of how Moose does constructors
    # that are inherited by non-Moose classes
    # - SL

    has 'first_name' => (is => 'rw', default => 'stevan', lazy => 1);
    has 'last_name'  => (is => 'rw', default => 'little', lazy => 1);

    __PACKAGE__->meta->make_immutable;
}

{
    package Employee;
    use Moxie;

    extends 'Moxie::Object', 'Person';

    has 'manager';

    sub REPR {
        my ($class, $proto) = @_;
        $class->Person::new( $proto );
    }

    sub manager : rw;
}

#warn Dumper mop::meta('Employee');

my $e = Employee->new;
isa_ok($e, 'Employee');
isa_ok($e, 'Person');

ok($e->can('first_name'), '... $e can call first_name');
ok($e->can('last_name'), '... $e can call last_name');
ok($e->can('manager'), '... $e can call manager');

is($e->first_name, 'stevan', '... got the expected default value');
is($e->last_name, 'little', '... got the expected default value');

my $m = Employee->new( first_name => 'pointy', last_name => 'hairedboss' );

$e->manager($m);
is_deeply($e->manager, $m, '... got the expected manager');

my $m2 = Employee->new( first_name => 'mr', last_name => 'burns', manager => $m );

is_deeply($m2->manager, $m, '... got the expected manager');

#warn Dumper $e;
#warn Dumper mop::meta('Employee');

is_deeply(
    mro::get_linear_isa('Employee'),
    [ 'Employee', 'Moxie::Object', 'UNIVERSAL::Object', 'Person', 'Moose::Object' ],
    '... got the expected linear isa'
);

done_testing;
