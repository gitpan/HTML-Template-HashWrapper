package HTML::Template::HashWrapper;
use strict;
use Carp;

our $VERSION = '1.0';

sub new {
  my $class = shift;
  my $wrapped = shift;
  unless ( UNIVERSAL::isa($wrapped, 'HASH') ) {
    croak "Wrapped object is not a hash reference";
  }
  my %args = @_;
  my $ref_to_bless;
  my $at_isa;
  if ( $args{nobless} ) {
    $at_isa = 'HTML::Template::HashWrapper::Plain';
    $ref_to_bless = \$wrapped;
  } else {
    $at_isa = $class;
    $ref_to_bless = $wrapped;
  }
  my $uniq = "ANON_".$$.time().int(rand()*10000);
  my $pkgname = "$ {class}::$ {uniq}";
  if ( UNIVERSAL::isa( $wrapped, 'UNIVERSAL' ) ) {
    # $wrapped is already blessed: add its ref to @ISA
    $at_isa .= " " . ref($wrapped);
  }
  eval "{package $pkgname; use strict; our \@ISA=qw($at_isa); 1;}";
  die $@ if $@;
  return bless $ref_to_bless, $pkgname;
}

# XXX according to H::T, param() can also support:
#     set multiple params: hash input
#     set multuple params from a hashref input

# Standard behavior: $self is a hashref
sub param {
  my $self = shift;
  my($name, $value) = @_;
  if ( defined($name) ) {
    if (defined($value)) {
      return $self->{$name} = $value;
    } else {
      return $self->{$name};
    }
  } else {
    return keys %{$self};
  }
}


1;

package HTML::Template::HashWrapper::Plain;
our @ISA=('HTML::Template::HashWrapper');

# Un-reblessing behavior: $self is a hashref-ref
sub param {
  my $self = shift;
  my($name, $value) = @_;
  if ( defined($name) ) { 
    if (defined($value)) {
      return $ {$self}->{$name} = $value;
    } else {
      return $ {$self}->{$name};
    }
  } else {
    return keys %{$$self};
  }
}

1;
__END__

=pod

=head1 NAME

HTML::Template::HashWrapper - Easy association with HTML::Template

=head1 SYNOPSIS

  use HTML::Template;
  use HTML::Template::HashWrapper;

  my $context = { var1 => 'Stuff',
		  var2 => [ { name => 'Name1', value => 'Val1', },
			    { name => 'Name2', value => 'Val2', },
			  ],
		};

  my $template = HTML::Template->new
    ( associate => HTML::Template::HashWrapper->new( $context ) );

  # Some::Object creates blessed hash references:
  my $something = Some::Object->new();
  my $wrapper = HTML::Template::HashWrapper->new( $something );
  my $template = HTML::Template->new( associate => $wrapper );

  # the wrapper keeps the original's interface:
  my $val1 = $something->somemethod( 251 );
  my $val2 = $wrapper->somemethod( 251 );

=head1 DESCRIPTION

HTML::Template::HashWrapper provides a simple way to use arbitrary
hash references (and hashref-based objects) with HTML::Template's
C<associate> option.

C<new($ref)> returns an object with a C<param()> method which conforms
to HTML::Template's expected interface:

=over 4

=item

C<param($key)> returns the value of C<$ref-E<gt>{$key}>.

=item

C<param()> with no argument returns the set of keys.

=item

C<param($key,$value)> may also be used to set values in the underlying
hash.

=back

By default, HTML::Template::HashWrapper works by re-blessing the input
object (or blessing, if the input is an unblessed hash reference) into
a new package which extends the original package and provides an
implementation of C<param()>.  If for some reason the input reference
cannot be re-blessed, you may create the wrapper with this form of C<new()>:

    $wrapper = HTML::Template::HashWrapper->new( $obj, nobless => 1 );

The C<nobless> option will force HashWrapper to create a new object,
but leave the original reference in its original state of blessing.

In either case, all methods on the original object's class can be
called on the newly created object.

=head1 NOTES

In theory, C<param()> should also support setting multiple parameters
by passing in a hash or hash reference.  This interface currently does
not support that, but HTML::Template only uses the two supported
forms.

Should you decide to subclass HTML::Template::HashWrapper, be aware
that in the C<nobless> case, the package name for the base class is
hardcoded.

=head1 AUTHOR

Greg Fast <gdf@speakeasy.net>

=head1 COPYRIGHT

Copyright 2003 Greg Fast (gdf@speakeasy.net)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
