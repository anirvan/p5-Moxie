#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use MOP;

package Foo {
    use Moxie;

    has _bar => sub { 'bar' };

    my sub _bar : private;

    sub bar { _bar }
}

package Baz {
    use Moxie;

    with 'Foo';

    sub baz ($self) { join ", " => $self->bar, 'baz' }
}

package Gorch {
    use Moxie;

    extends 'Moxie::Object';
       with 'Baz';
}

{
    my $baz_meta = MOP::Role->new( name => 'Baz' );

    ok( $baz_meta->does_role( 'Foo' ), '... Baz does the Foo role');

    my $bar_method = $baz_meta->get_method('bar');
    ok( $bar_method->isa( 'MOP::Method' ), '... got a method object' );
    is( $bar_method->name, 'bar', '... got the method we expected' );

    my $baz_method = $baz_meta->get_method('baz');
    ok( $baz_method->isa( 'MOP::Method' ), '... got a method object' );
    is( $baz_method->name, 'baz', '... got the method we expected' );

    my $bar_slot = $baz_meta->get_slot_alias('_bar');
    ok( $bar_slot->isa( 'MOP::Slot' ), '... got an slot object' );
    is( $bar_slot->name, '_bar', '... got the slot we expected' );

    my $bar_method_alias = $baz_meta->get_method_alias('bar');
    ok( $bar_method_alias->isa( 'MOP::Method' ), '... got a method object' );
    is( $bar_method_alias->name, 'bar', '... got the method we expected' );
}

{
    my $gorch_meta = MOP::Role->new( name => 'Gorch' );

    is_deeply([ $gorch_meta->roles ], [ 'Baz' ], '... got the list of expected roles');

    my $bar_method = $gorch_meta->get_method_alias('bar');
    ok( $bar_method->isa( 'MOP::Method' ), '... got a method object' );
    is( $bar_method->name, 'bar', '... got the method we expected' );

    my $baz_method = $gorch_meta->get_method_alias('baz');
    ok( $baz_method->isa( 'MOP::Method' ), '... got a method object' );
    is( $baz_method->name, 'baz', '... got the method we expected' );

    my $bar_slot = $gorch_meta->get_slot_alias('_bar');
    ok( $bar_slot->isa( 'MOP::Slot' ), '... got an slot object' );
    is( $bar_slot->name, '_bar', '... got the slot we expected' );
}

{
    my $gorch = Gorch->new;
    isa_ok($gorch, 'Gorch');

    ok($gorch->DOES('Baz'), '... gorch does Baz');
    ok($gorch->DOES('Foo'), '... gorch does Foo');

    can_ok($gorch, 'bar');
    can_ok($gorch, 'baz');

    is($gorch->baz, 'bar, baz', '... got the expected output');
}

done_testing;
