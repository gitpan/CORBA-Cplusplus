use strict;
use UNIVERSAL;

#
#			Interface Definition Language (OMG IDL CORBA v3.0)
#
#			C++ Language Mapping Specification, New Edition June 1999
#

package CORBA::Cplusplus::lengthVisitor;

use CORBA::C::type;

use base qw(CORBA::C::lengthVisitor);

# builds $node->{length}

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);
	my ($parser) = @_;
	$self->{srcname} = $parser->YYData->{srcname};
	$self->{symbtab} = $parser->YYData->{symbtab};
	$self->{done_hash} = {};
	$self->{key} = 'cpp_name';
	return $self;
}

#	See	1.9		Mapping for Structured Types
#

sub _get_length {
	my $self = shift;
	my ($type) = @_;
	if (	   $type->isa('AnyType')
			or $type->isa('SequenceType')
			or $type->isa('StringType')
			or $type->isa('WideStringType')
			or $type->isa('ObjectType')
			or $type->isa('RegularValue')
			or $type->isa('BoxedValue')
			or $type->isa('AbstractValue') ) {
		return 'variable';
	}
	if (	   $type->isa('StructType')
			or $type->isa('UnionType')
			or $type->isa('TypeDeclarator') ) {
		return $type->{length};
	}
	return undef;
}

#
#	3.8		Interface Declaration
#

sub visitBaseInterface {
	my $self = shift;
	my ($node) = @_;
	return if (exists $node->{length});
	$node->{length} = 'variable';
	foreach (@{$node->{list_export}}) {
		$self->{symbtab}->Lookup($_)->visit($self);
	}
}

sub visitForwardBaseInterface {
	my $self = shift;
	my ($node) = @_;
	return if (exists $node->{length});
	$node->{length} = 'variable';
}

#
#	3.9		Value Declaration
#

sub visitStateMember {
	my $self = shift;
	my ($node) = @_;
	$self->_get_defn($node->{type})->visit($self);
}

sub visitInitializer {
	my $self = shift;
	my ($node) = @_;
	foreach (@{$node->{list_param}}) {
		$self->_get_defn($_->{type})->visit($self);
	}
}

##############################################################################

package CORBA::Cplusplus::typeVisitor;

use CORBA::C::type;

use base qw(CORBA::C::typeVisitor);

# builds $node->{cpp_arg}

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);
	my ($parser) = @_;
	$self->{srcname} = $parser->YYData->{srcname};
	$self->{symbtab} = $parser->YYData->{symbtab};
	return $self;
}

#
#	3.9		Value Declaration
#

sub visitInitializer {
	my $self = shift;
	my ($node) = @_;
	foreach (@{$node->{list_param}}) {	# parameter
		my $type = $self->_get_type($_->{type});
		$_->{cpp_arg} = CORBA::Cplusplus::nameattr->NameAttr($self->{symbtab}, $type, $_->{cpp_name}, $_->{attr});
	}
}

#
#	3.13	Operation Declaration
#

sub visitOperation {
	my $self = shift;
	my ($node) = @_;
	my $type = $self->_get_type($node->{type});
	$node->{cpp_arg} = CORBA::Cplusplus::nameattr->NameAttr($self->{symbtab}, $type, '', 'return');
	foreach (@{$node->{list_param}}) {	# parameter
		$type = $self->_get_type($_->{type});
		$_->{cpp_arg} = CORBA::Cplusplus::nameattr->NameAttr($self->{symbtab}, $type, $_->{cpp_name}, $_->{attr});
	}
}

##############################################################################

package CORBA::Cplusplus::nameattr;

#
#	See 1.22	Argument Passing Considerations
#

# needs $node->{cpp_name} and $node->{length}

sub NameAttr {
	my $proto = shift;
	my ($symbtab, $node, $v_name, $attr) = @_;
	my $class = ref $node;
	$class = "BasicType" if ($node->isa("BasicType"));
	$class = "AnyType" if ($node->isa("AnyType"));
	$class = "BaseInterface" if ($node->isa("BaseInterface"));
	$class = "ForwardBaseInterface" if ($node->isa("ForwardBaseInterface"));
	my $func = 'NameAttr' . $class;
	if($proto->can($func)) {
		return $proto->$func($symbtab, $node, $v_name, $attr);
	} else {
		warn "Please implement a function '$func' in '",__PACKAGE__,"'.\n";
	}
}

sub NameAttrBaseInterface {
	my $proto = shift;
	my ($symbtab, $node, $v_name, $attr) = @_;
	my $t_name = $node->{cpp_name};
	if (      $attr eq 'in' ) {
		return $t_name . "_ptr "   . $v_name;
	} elsif ( $attr eq 'inout' ) {
		return $t_name . "_out " . $v_name;
	} elsif ( $attr eq 'out' ) {
		return $t_name . "_out " . $v_name;
	} elsif ( $attr eq 'return' ) {
		return $t_name . "_ptr";
	} else {
		warn __PACKAGE__,"::NameBaseInterface : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrForwardBaseInterface {
	my $proto = shift;
	my ($symbtab, $node, $v_name, $attr) = @_;
	my $t_name = $node->{cpp_name};
	if (      $attr eq 'in' ) {
		return $t_name . "_ptr "   . $v_name;
	} elsif ( $attr eq 'inout' ) {
		return $t_name . "_out " . $v_name;
	} elsif ( $attr eq 'out' ) {
		return $t_name . "_out " . $v_name;
	} elsif ( $attr eq 'return' ) {
		return $t_name . "_ptr";
	} else {
		warn __PACKAGE__,"::NameForwardBaseInterface : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrTypeDeclarator {	# TODO
	my $proto = shift;
	my ($symbtab, $node, $v_name, $attr) = @_;
	if (exists $node->{array_size}) {
#		my $t_name = $node->{type}->{c_name};
#		my $array = '';
#		foreach (@{$node->{array_size}}) {
#			$array .= "[" . $_->{c_literal} . "]";
#		}
		my $t_name = $node->{cpp_ns} . "::" . $node->{cpp_name};
		if (      $attr eq 'in' ) {
#			return $t_name . " " . $v_name . $array;
			return $t_name . " " . $v_name;
		} elsif ( $attr eq 'inout' ) {
#			return $t_name . " " . $v_name . $array;
			return $t_name . " " . $v_name;
		} elsif ( $attr eq 'out' ) {
			if (defined $node->{length}) {		# variable
				return $t_name . "_slice ** " . $v_name;
			} else {
#				return $t_name . " " . $v_name . $array;
				return $t_name . " " . $v_name;
			}
		} elsif ( $attr eq 'return' ) {
			return $t_name . "_slice *";
		} else {
			warn __PACKAGE__,"::NameTypeDeclarator array : ERROR_INTERNAL $attr \n";
		}
	} else {
		if (exists $node->{modifier}) {		# native
			my $t_name = $node->{c_name};
			if (      $attr eq 'in' ) {
				return $t_name . " "   . $v_name;
			} elsif ( $attr eq 'inout' ) {
				return $t_name . " * " . $v_name;
			} elsif ( $attr eq 'out' ) {
				return $t_name . " * " . $v_name;
			} elsif ( $attr eq 'return' ) {
				return $t_name;
			} else {
				warn __PACKAGE__,"::NameAttrTypeDeclarator : ERROR_INTERNAL $attr \n";
			}
		} else {
			my $type = $node->{type};
			unless (ref $type) {
				$type = $symbtab->Lookup($type);
			}
			return $proto->NameAttr($symbtab, $type, $v_name, $attr);
		}
	}
}

sub NameAttrBasicType {
	my $proto = shift;
	my ($symbtab, $node, $v_name, $attr) = @_;
	my $t_name = $node->{cpp_ns} . "::" . $node->{cpp_name};
	if (      $attr eq 'in' ) {
		return $t_name . " "   . $v_name;
	} elsif ( $attr eq 'inout' ) {
		return $t_name . "_out " . $v_name;
	} elsif ( $attr eq 'out' ) {
		return $t_name . "_out " . $v_name;
	} elsif ( $attr eq 'return' ) {
		return $t_name;
	} else {
		warn __PACKAGE__,"::NameBasicType : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrAnyType {	# TODO
	my $proto = shift;
	my ($symbtab, $node, $v_name, $attr) = @_;
	$node->{length} = 'variable';
	my $t_name = $node->{cpp_ns} . "::" . $node->{cpp_name};
	if (      $attr eq 'in' ) {
		return $t_name . " * "  . $v_name;
	} elsif ( $attr eq 'inout' ) {
		return $t_name . " * "  . $v_name;
	} elsif ( $attr eq 'out' ) {
		return $t_name . " ** " . $v_name;
	} elsif ( $attr eq 'return' ) {
		return $t_name . " *";
	} else {
		warn __PACKAGE__,"::NameAnyType : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrStructType {	# TODO
	my $proto = shift;
	my ($symbtab, $node, $v_name, $attr) = @_;
	my $t_name = $node->{cpp_ns} . "::" . $node->{cpp_name};
	if (      $attr eq 'in' ) {
		return $t_name . " * " . $v_name;
	} elsif ( $attr eq 'inout' ) {
		return $t_name . " * " . $v_name;
	} elsif ( $attr eq 'out' ) {
		if (defined $node->{length}) {		# variable
			return $t_name . " ** " . $v_name;
		} else {
			return $t_name . " * "  . $v_name;
		}
	} elsif ( $attr eq 'return' ) {
		if (defined $node->{length}) {		# variable
			return $t_name . " *";
		} else {
			return $t_name;
		}
	} else {
		warn __PACKAGE__,"::NameStructType : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrUnionType {		# TODO
	my $proto = shift;
	my ($symbtab, $node, $v_name, $attr) = @_;
	my $t_name = $node->{cpp_ns} . "::" . $node->{cpp_name};
	if (      $attr eq 'in' ) {
		return $t_name . " * " . $v_name;
	} elsif ( $attr eq 'inout' ) {
		return $t_name . " * " . $v_name;
	} elsif ( $attr eq 'out' ) {
		if (defined $node->{length}) {		# variable
			return $t_name . " ** " . $v_name;
		} else {
			return $t_name . " * "  . $v_name;
		}
	} elsif ( $attr eq 'return' ) {
		if (defined $node->{length}) {		# variable
			return $t_name . " *";
		} else {
			return $t_name;
		}
	} else {
		warn __PACKAGE__,"::NameUnionType : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrEnumType {
	my $proto = shift;
	my ($symbtab, $node, $v_name, $attr) = @_;
	my $t_name = $node->{cpp_ns} . "::" . $node->{cpp_name};
	if (      $attr eq 'in' ) {
		return $t_name . " "   . $v_name;
	} elsif ( $attr eq 'inout' ) {
		return $t_name . "_out " . $v_name;
	} elsif ( $attr eq 'out' ) {
		return $t_name . "_out " . $v_name;
	} elsif ( $attr eq 'return' ) {
		return $t_name;
	} else {
		warn __PACKAGE__,"::NameEnumType : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrSequenceType {	# TODO
	my $proto = shift;
	my ($symbtab, $node, $v_name, $attr) = @_;
	my $t_name = $node->{cpp_ns} . "::" . $node->{cpp_name};
	if (      $attr eq 'in' ) {
		return $t_name . " * "  . $v_name;
	} elsif ( $attr eq 'inout' ) {
		return $t_name . " * "  . $v_name;
	} elsif ( $attr eq 'out' ) {
		return $t_name . " ** " . $v_name;
	} elsif ( $attr eq 'return' ) {
		return $t_name . " *";
	} else {
		warn __PACKAGE__,"::NameSequenceType : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrStringType {
	my $proto = shift;
	my ($symbtab, $node, $v_name, $attr) = @_;
	my $t_name = $node->{cpp_ns} . "::" . $node->{cpp_name};
	if (      $attr eq 'in' ) {
		return "const " . $t_name . " "   . $v_name;
	} elsif ( $attr eq 'inout' ) {
		return $t_name . "_out " . $v_name;
	} elsif ( $attr eq 'out' ) {
		return $t_name . "_out " . $v_name;
	} elsif ( $attr eq 'return' ) {
		return $t_name;
	} else {
		warn __PACKAGE__,"::NameStringType : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrWideStringType {
	my $proto = shift;
	my ($symbtab, $node, $v_name, $attr) = @_;
	my $t_name = $node->{cpp_ns} . "::" . $node->{cpp_name};
	if (      $attr eq 'in' ) {
		return "const " . $t_name . " "   . $v_name;
	} elsif ( $attr eq 'inout' ) {
		return $t_name . "_out " . $v_name;
	} elsif ( $attr eq 'out' ) {
		return $t_name . "_out " . $v_name;
	} elsif ( $attr eq 'return' ) {
		return $t_name;
	} else {
		warn __PACKAGE__,"::NameWideStringType : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrFixedPtType {	# TODO
	my $proto = shift;
	my ($symbtab, $node, $v_name, $attr) = @_;
	my $t_name = $node->{cpp_ns} . "::" . $node->{cpp_name};
	if (      $attr eq 'in' ) {
		return $t_name . " * "  . $v_name;
	} elsif ( $attr eq 'inout' ) {
		return $t_name . " * " . $v_name;
	} elsif ( $attr eq 'out' ) {
		return $t_name . " * " . $v_name;
	} elsif ( $attr eq 'return' ) {
		return $t_name;
	} else {
		warn __PACKAGE__,"::NameFixedPtType : ERROR_INTERNAL $attr \n";
	}
}

sub NameAttrVoidType {
	my $proto = shift;
	my ($symbtab, $node, $v_name, $attr) = @_;
	my $t_name = $node->{cpp_name};
	if ($attr ne 'return') {
		warn __PACKAGE__,"::NameVoidType : ERROR_INTERNAL \n";
	}
	return $t_name;
}

1;

