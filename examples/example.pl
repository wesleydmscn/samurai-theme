use strict;
use warnings;
use POSIX qw(floor);
use List::Util qw(reduce sum0 max min);

package Product;

sub new {
    my ($class, %args) = @_;
    return bless {
        id    => $args{id},
        name  => $args{name},
        price => $args{price},
        stock => $args{stock},
    }, $class;
}

sub id    { $_[0]->{id}    }
sub name  { $_[0]->{name}  }
sub price { $_[0]->{price} }
sub stock { $_[0]->{stock} }

package CartItem;

sub new {
    my ($class, $product, $qty) = @_;
    return bless { product => $product, qty => $qty }, $class;
}

sub product  { $_[0]->{product} }
sub qty      { $_[0]->{qty}     }
sub subtotal { $_[0]->{product}->price * $_[0]->{qty} }

package Cart;

sub new { bless { items => {} }, $_[0] }

sub add {
    my ($self, $product, $qty) = @_;
    $qty //= 1;
    my $id = $product->id;
    if (exists $self->{items}{$id}) {
        $self->{items}{$id}{qty} += $qty;
    } else {
        $self->{items}{$id} = CartItem->new($product, $qty);
    }
}

sub subtotal {
    my ($self) = @_;
    return sum0(map { $_->subtotal } values %{ $self->{items} });
}

sub total {
    my ($self, $discount) = @_;
    my $sub = $self->subtotal;
    return $discount ? $discount->($sub) : $sub;
}

package Repository;

sub new { bless { store => {} }, $_[0] }

sub save {
    my ($self, $entity) = @_;
    $self->{store}{ $entity->id } = $entity;
}

sub find {
    my ($self, $id) = @_;
    return $self->{store}{$id};
}

sub find_all {
    my ($self) = @_;
    return values %{ $self->{store} };
}

package Discount;

sub percentage {
    my ($percent) = @_;
    return sub { $_[0] * (1 - $percent / 100) };
}

sub fixed {
    my ($amount) = @_;
    return sub { max(0, $_[0] - $amount) };
}

package Math::Util;

sub fibonacci {
    my ($n) = @_;
    my @seq;
    my ($a, $b) = (0, 1);
    for (1 .. $n) {
        push @seq, $a;
        ($a, $b) = ($b, $a + $b);
    }
    return @seq;
}

sub sieve {
    my ($limit) = @_;
    my @flags = (1) x ($limit + 1);
    $flags[0] = $flags[1] = 0;
    for my $i (2 .. floor(sqrt($limit))) {
        next unless $flags[$i];
        for (my $j = $i * $i; $j <= $limit; $j += $i) {
            $flags[$j] = 0;
        }
    }
    return grep { $flags[$_] } 2 .. $limit;
}

package main;

my $repo = Repository->new;
$repo->save(Product->new(id => '1', name => 'Laptop',   price => 999.99, stock => 10));
$repo->save(Product->new(id => '2', name => 'Mouse',    price =>  29.99, stock => 50));
$repo->save(Product->new(id => '3', name => 'Keyboard', price =>  79.99, stock => 30));

my $cart = Cart->new;
$cart->add($repo->find('1'), 1);
$cart->add($repo->find('2'), 2);

my $discount = Discount::percentage(10);
printf "Subtotal:   \$%.2f\n", $cart->subtotal;
printf "After 10%%: \$%.2f\n", $cart->total($discount);

my @affordable = sort { $a->price <=> $b->price }
                 grep { $_->price < 100 }
                 $repo->find_all;

print 'Affordable: ', join(', ', map { $_->name } @affordable), "\n";
print 'Fibonacci(8): ', join(', ', Math::Util::fibonacci(8)), "\n";
print 'Primes up to 30: ', join(', ', Math::Util::sieve(30)), "\n";
