use strict;
use UNIVERSAL;

#
#			Interface Definition Language (OMG IDL CORBA v3.0)
#
#			C++ Language Mapping Specification, New Edition June 1999
#

package CplusplusLiteralVisitor;

use CORBA::C::literal;

use base qw(CliteralVisitor);

# needs $node->{cpp_name} (CplusplusNameVisitor) for Enum
# builds $node->{cpp_literal}

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);
	my($parser) = @_;
	$self->{key} = 'cpp_literal';
	$self->{symbtab} = $parser->YYData->{symbtab};
	return $self;
}

sub _Eval {
	my $self = shift;
	my($list_expr, $type) = @_;
	my $elt = pop @{$list_expr};
	unless (ref $elt) {
		$elt = $self->{symbtab}->Lookup($elt);
	}
	if (       $elt->isa('BinaryOp') ) {
		my $right = $self->_Eval($list_expr, $type);
		if (	   $elt->{op} eq '>>'
				or $elt->{op} eq '<<' ) {
			$right =~ s/[LU]+$//;
		}
		my $left = $self->_Eval($list_expr, $type);
		return "(" . $left . " " . $elt->{op} . " " . $right . ")";
	} elsif (  $elt->isa('UnaryOp') ) {
		my $right = $self->_Eval($list_expr, $type);
		return $elt->{op} . $right;
	} elsif (  $elt->isa('Constant') ) {
		return $elt->{cpp_name};
	} elsif (  $elt->isa('Enum') ) {
		return $elt->{cpp_name};
	} elsif (  $elt->isa('Literal') ) {
		$elt->visitName($self, $type);
		return $elt->{$self->{key}};
	} else {
		warn __PACKAGE__," _Eval: INTERNAL ERROR ",ref $elt,".\n";
		return undef;
	}
}

sub visitNameBooleanLiteral {
	my $self = shift;
	my($node) = @_;
	if ($node->{value} eq 'TRUE') {
		$node->{$self->{key}} = 'true';
	} else {
		$node->{$self->{key}} = 'false';
	}
}

1;

