#!perl

use strict;
use warnings;

use Test::More;

package Foo {
    use Moxie;

    sub foo { 'Foo::foo' }
}

package Foo2 {
    use Moxie;

    with 'Foo';

    sub foo { 'Foo2::foo' }
}

package Bar {
    use Moxie;

    sub foo { 'Bar::foo' }
}


{
    my $Foo2 = MOP::Role->new( name => 'Foo2' );
    is_deeply([$Foo2->required_methods], [], '... no method conflict here');
    ok($Foo2->has_method('foo'), '... Foo2 has the foo method');
    is($Foo2->get_method('foo')->body->(), 'Foo2::foo', '... the method in Foo2 is as we expected');
}


BEGIN {
    local $@ = undef;
    eval q[
        package FooBarBrokenRole {
            use Moxie;

            with 'Foo', 'Bar';
        }
    ];
    like(
        "$@",
        qr/^\[CONFLICT\] There should be no conflicting methods when composing \(Foo, Bar\) into \(FooBarBrokenRole\) but instead we found \(foo\)/,
        '... got the exception we expected'
    );
}

package FooBarClass {
    use Moxie;

    extends 'Moxie::Object';
       with 'Foo', 'Bar';

    sub foo { 'FooBarClass::foo' }
}

{
    my $FooBarClass = MOP::Class->new( name => 'FooBarClass' );
    my ($Foo, $Bar) = map { MOP::Role->new( name => $_ ) } qw[ Foo Bar ];
    is_deeply([$FooBarClass->required_methods], [], '... method conflict between roles results in required method');
    ok($FooBarClass->has_method('foo'), '... FooBarClass does have the foo method');
    is($FooBarClass->get_method('foo')->body->(), 'FooBarClass::foo', '... FooBarClass foo method is what makes sense');
    ok($Foo->has_method('foo'), '... Foo still has the foo method');
    ok($Bar->has_method('foo'), '... Bar still has the foo method');
}

BEGIN {
    local $@ = undef;
    eval q[
        package FooBarBrokenClass1 {
            use Moxie;

            extends 'Moxie::Object';
               with 'Foo', 'Bar';
        }
    ];
    like(
        "$@",
        qr/^\[CONFLICT\] There should be no conflicting methods when composing \(Foo, Bar\) into \(FooBarBrokenClass1\) but instead we found \(foo\)/,
        '... got the exception we expected'
    );
}

package Baz {
    use Moxie;

    extends 'Moxie::Object';
       with 'Foo';

    sub foo { 'Baz::foo' }
}

{
    my ($Baz, $Foo) = map { MOP::Class->new( name => $_ ) } qw[ Baz Foo ];
    is_deeply([$Baz->required_methods], [], '... no method conflict between class/role');
    ok($Foo->has_method('foo'), '... Foo still has the foo method');
    is(Baz->new->foo, 'Baz::foo', '... got the right method');
}

done_testing;
