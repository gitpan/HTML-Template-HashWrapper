#!/usr/bin/perl -w
use strict;
use Test::More qw(no_plan); # XXX
use Test::Exception;

BEGIN {
  use_ok( 'HTML::Template::HashWrapper' );
}

{ # package for testing extension of existing objects
  package Temp::Test;
  sub test {
    my $self = shift;
    return 31337;
  }
};

#----------------------------------------
# nobless => 0 (default)

{
  # new(hashref) should result in a H::T::HW::ANON_*
  my $simple = { guido => '251-5049',
		 cheap_company => '555-1212',
	       };
  ok( ref($simple) eq 'HASH', 'orig is a hashref');
  my $x = HTML::Template::HashWrapper->new($simple);
  # $simple is now blessed
  ok( ref($simple) ne 'HASH', 'orig is blessed' );
  isa_ok( $x, 'HTML::Template::HashWrapper');
  # $simple and $x are same reference
  ok( $simple eq $x, 'new and orig are same reference' );
  # param exists as a method
  can_ok( $x, 'param' );
  # param() returns the right value
  ok( $x->param('guido') eq $simple->{guido}, 'new obj can do param correct' );
  ok( $x->param('guido') eq '251-5049', 'data still exists in hashref' );
  # param($n,$v) is setter
  $x->param('newname', 'newval');
  ok( $x->param('newname') eq 'newval', 'param($x,$y) works as setter' );
  # test param() in list context => param names
  ok( scalar($x->param()) == 3, 'zero-arg param returns name list' );
  ok( grep('guido', $x->param()), 'param() returns name list (1)' );
  ok( grep('cheap_company', $x->param()), 'param() returns name list (2)' );
  ok( grep('newname', $x->param()), 'param() returns name list (3)' );
}

{
  # new(non-hashref) should result in death
  foreach my $bogus( 251, [2,5,1,5,0,4,9] ) {
    dies_ok {
      my $x = HTML::Template::HashWrapper->new($bogus);
    } "not allowed: wrapping $bogus";
  }
}

{
  # new($object) should result in a new H::T::HW::ANON,
  #    which extends $obj's class
  my $obj = bless { sneaky => 'devil' }, 'Temp::Test';
  ok( ref($obj), 'orig is a reference' );
  my $orig_type = ref($obj);
  my $x = HTML::Template::HashWrapper->new($obj);
  ok( defined($x), 'new returned something' );
  ok( $x eq $obj, 'returned ref is same ref as orig' );
  ok( ref($obj) ne $orig_type, 'original reblessed' );
  isa_ok( $x, $orig_type );
  isa_ok( $x, 'HTML::Template::HashWrapper' );
  can_ok( $x, 'param' );
  can_ok( $x, 'test' ); # $x should retain old interface
  ok( $x->test() == 31337, 'old interface still works' );
  ok( $x->param( 'sneaky' ) eq $x->{sneaky}, 'param works' );
  ok( $x->param( 'sneaky' ) eq 'devil', 'param works and data still exists' );
  # param($n,$v) is setter
  $x->param('newname', 'newval');
  ok( $x->param('newname') eq 'newval', 'param($x,$y) works as setter' );
}

#----------------------------------------
# nobless => 1

{
  # new(hashref, nobless => 0) should return a H::T::HW::Plain
  # should leave the original unblessed
  my $simple = { guido => '251-5049',
		 cheap_company => '555-1212',
	       };
  ok( ref($simple) eq 'HASH', 'orig is a hashref');
  my $x = HTML::Template::HashWrapper->new($simple, nobless => 1 );
  # $simple is still blessed
  ok( ref($simple) eq 'HASH', 'orig remains unblessed' );
  isa_ok( $x, 'HTML::Template::HashWrapper');
  # $simple and $x are different references
  ok( $simple ne $x, 'new and orig are different references' );
  # param exists as a method
  can_ok( $x, 'param' );
  # param() returns the right value
  ok( $x->param('guido') eq $simple->{guido}, 'new obj can do param correct' );
  ok( $x->param('guido') eq '251-5049', 'data still exists in hashref' );
  # param($n,$v) is setter
  $x->param('newname', 'newval');
  ok( $x->param('newname') eq 'newval', 'param($x,$y) works as setter' );
  # param setter also modifies original hash
  ok( $simple->{newname} eq 'newval', 'param($x) modifies original' );
  # test param() in list context => param names
  ok( scalar($x->param()) == 3, 'zero-arg param returns name list' );
  ok( grep('guido', $x->param()), 'param() returns name list (1)' );
  ok( grep('cheap_company', $x->param()), 'param() returns name list (2)' );
  ok( grep('newname', $x->param()), 'param() returns name list (3)' );
}

{
  # new(non-hashref) should result in death - unchanged for nobless
  foreach my $bogus( 251, [2,5,1,5,0,4,9] ) {
    dies_ok {
      my $x = HTML::Template::HashWrapper->new($bogus, nobless=>1 );
    } "not allowed: wrapping $bogus";
  }
}

{
  # new($object, nobless=>1) should result in a new H::T::HW::Plain
  #    which extends $obj's class
  my $obj = bless { sneaky => 'devil' }, 'Temp::Test';
  ok( ref($obj), 'orig is a reference' );
  my $orig_type = ref($obj);
  my $x = HTML::Template::HashWrapper->new($obj, nobless => 1);
  ok( defined($x), 'new returned something' );
  ok( $x ne $obj, 'returned ref is not same ref as orig' );
  ok( ref($obj) eq $orig_type, 'original is not reblessed' );
  isa_ok( $x, $orig_type );
  isa_ok( $x, 'HTML::Template::HashWrapper' );
  can_ok( $x, 'param' );
  can_ok( $x, 'test' ); # $x should retain old interface
  ok( $x->test() == 31337, 'old interface still works' );
  ok( $x->param( 'sneaky' ) eq ${$x}->{sneaky}, 'param works' );
  ok( $x->param( 'sneaky' ) eq 'devil', 'param works and data still exists' );
  # param($n,$v) is setter
  $x->param('newname', 'newval');
  ok( $x->param('newname') eq 'newval', 'param($x,$y) works as setter' );
}
