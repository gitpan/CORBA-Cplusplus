use strict;
use UNIVERSAL;

#
#			Interface Definition Language (OMG IDL CORBA v3.0)
#
#			C++ Language Mapping Specification, New Edition June 1999
#

package CplusplusNameVisitor;

# builds $node->{cpp_name} and $node->{cpp_ns}

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);
	my($parser) = @_;
	$self->{key} = 'cpp_name';
	$self->{symbtab} = $parser->YYData->{symbtab};
	$self->{cpp_keywords} = {		# See 1.43	C++ Keywords
		'and'				=> 1,
		'and_ep'			=> 1,
		'asm'				=> 1,
		'auto'				=> 1,
		'bitand'			=> 1,
		'bitor'				=> 1,
		'bool'				=> 1,
		'break'				=> 1,
#IDL	'case'				=> 1,
		'catch'				=> 1,
#IDL	'char'				=> 1,
		'class'				=> 1,
		'compl'				=> 1,
#IDL	'const'				=> 1,
		'const_cast'		=> 1,
		'continue'			=> 1,
#IDL	'default'			=> 1,
		'delete'			=> 1,
		'do'				=> 1,
#IDL	'double'			=> 1,
		'dynamic_cast'		=> 1,
		'else'				=> 1,
#IDL	'enum'				=> 1,
		'explicit'			=> 1,
		'export'			=> 1,
		'extern'			=> 1,
#IDL	'false'				=> 1,
#IDL	'float'				=> 1,
		'for'				=> 1,
		'friend'			=> 1,
		'goto'				=> 1,
		'if'				=> 1,
		'inline'			=> 1,
		'int'				=> 1,
#IDL	'long'				=> 1,
		'mutable'			=> 1,
		'namespace'			=> 1,
		'new'				=> 1,
		'not'				=> 1,
		'not_eq'			=> 1,
		'operator'			=> 1,
		'or'				=> 1,
		'or_eq'				=> 1,
		'private'			=> 1,
		'protected'			=> 1,
		'public'			=> 1,
		'register'			=> 1,
		'reinterpret_cast'	=> 1,
		'return'			=> 1,
#IDL	'short'				=> 1,
		'signed'			=> 1,
		'sizeof'			=> 1,
		'static'			=> 1,
		'static_cast'		=> 1,
#IDL	'struct'			=> 1,
#IDL	'switch'			=> 1,
		'template'			=> 1,
		'this'				=> 1,
		'throw'				=> 1,
#IDL	'true'				=> 1,
		'try'				=> 1,
#IDL	'typedef'			=> 1,
		'typeid'			=> 1,
		'typename'			=> 1,
#IDL	'union'				=> 1,
#IDL	'unsigned'			=> 1,
		'using'				=> 1,
		'virtual'			=> 1,
#IDL	'void'				=> 1,
		'volatile'			=> 1,
		'wchar_t'			=> 1,
		'while'				=> 1,
		'xor'				=> 1,
		'xor_eq'			=> 1
	};
	return $self;
}

sub _get_name {			# See 1.1.2 Scoped Names
	my $self = shift;
	my($node) = @_;
	my $name = $node->{idf};
	$name =~ s/^_get_//;
	$name =~ s/^_set_//;
	if (exists $self->{cpp_keywords}->{name}) {
		return "_cxx_" . $name;
	} else {
		return $name;
	}
}

sub _get_ns {
	my $self = shift;
	my($node) = @_;
	my $pkg = $node->{full};
	$pkg =~ s/::[0-9A-Z_a-z]+$//;
	return '' unless ($pkg);
	my $defn = $self->{symbtab}->Lookup($pkg);
	if (	   $defn->isa('StructType')
			or $defn->isa('UnionType')
			or $defn->isa('ExceptionType') ) {
		$pkg =~ s/::[0-9A-Z_a-z]+$//;
	}
	return '' unless ($pkg);
	my $ns = '';
	$pkg =~ s/^:://;
	foreach (split /::/, $pkg) {
		if (exists $self->{cpp_keywords}->{$_}) {
			$ns .= "::_cxx_" . $_;
		} else {
			$ns .= "::" . $_;
		}
	}
	$ns =~ s/^:://;
	return $ns;
}

sub _get_defn {
	my $self = shift;
	my($defn) = @_;
	if (ref $defn) {
		return $defn;
	} else {
		return $self->{symbtab}->Lookup($defn);
	}
}

#
#	3.5		OMG IDL Specification
#

sub visitNameSpecification {
	my $self = shift;
	my($node) = @_;
	foreach (@{$node->{list_export}}) {
		$self->{symbtab}->Lookup($_)->visitName($self);
	}
}

#
#	3.7		Module Declaration
#

sub visitNameModules {
	my $self = shift;
	my($node) = @_;
	my $ns_save = $self->{ns_curr};
	$node->{cpp_ns} = $self->_get_ns($node);
	$node->{cpp_name} = $self->_get_name($node);
	foreach (@{$node->{list_export}}) {
		$self->{symbtab}->Lookup($_)->visitName($self);
	}
}

#
#	3.8		Interface Declaration
#

sub visitNameBaseInterface {
	my $self = shift;
	my($node) = @_;
	return if (exists $node->{cpp_name});
	$node->{cpp_ns} = $self->_get_ns($node);
	$node->{cpp_name} = $self->_get_name($node);
	$node->{cpp_has_ptr} = 1;
	$node->{cpp_has_var} = 1;
	foreach (@{$node->{list_export}}) {
		$self->{symbtab}->Lookup($_)->visitName($self);
	}
}

#
#	3.9		Value Declaration
#

sub visitNameStateMember {
	my $self = shift;
	my($node) = @_;
	$node->{cpp_ns} = $self->_get_ns($node);
	$node->{cpp_name} = $self->_get_name($node);
	$self->_get_defn($node->{type})->visitName($self);
}

sub visitNameInitializer {
	my $self = shift;
	my($node) = @_;
	$node->{cpp_ns} = $self->_get_ns($node);
	$node->{cpp_name} = $self->_get_name($node);
	foreach (@{$node->{list_param}}) {
		$_->visitName($self);			# parameter
	}
}

#
#	3.10	Constant Declaration
#

sub visitNameConstant {
	my $self = shift;
	my($node) = @_;
	$node->{cpp_ns} = $self->_get_ns($node);
	$node->{cpp_name} = $self->_get_name($node);
	$self->_get_defn($node->{type})->visitName($self);
}

sub visitNameExpression {
	# empty
}

#
#	3.11	Type Declaration
#

sub visitNameTypeDeclarator {
	my $self = shift;
	my($node) = @_;
	return if (exists $node->{cpp_ns});
	$node->{cpp_ns} = $self->_get_ns($node);
	$node->{cpp_name} = $self->_get_name($node);
	unless (exists $node->{modifier}) {		# native
		$node->{cpp_ns} = $self->_get_ns($node);
		$node->{cpp_name} = $self->_get_name($node);
		my $type = $self->_get_defn($node->{type});
		if ($type->isa('SequenceType') and !exists $node->{array_size}) {
			$type->{repos_id} = $node->{repos_id};
			$node->{cpp_has_var} = 1;
			$type->visitName($self, $node->{cpp_name});
		} else {
			$type->visitName($self);
		}
	}
}

#
#	3.11.1	Basic Types
#
#	See	1.5		Mapping for Basic Data Types
#

sub visitNameBasicType {
	my $self = shift;
	my($node) = @_;
	$node->{cpp_ns} = "CORBA";
	if      ($node->isa('FloatingPtType')) {
		if      ($node->{value} eq 'float') {
			$node->{cpp_name} = "Float";
		} elsif ($node->{value} eq 'double') {
			$node->{cpp_name} = "Double";
		} elsif ($node->{value} eq 'long double') {
			$node->{cpp_name} = "LongDouble";
		} else {
			warn __PACKAGE__,"::visitNameBasicType (FloatingType) $node->{value}.\n"
		}
	} elsif ($node->isa('IntegerType')) {
		if      ($node->{value} eq 'short') {
			$node->{cpp_name} = "Short";
		} elsif ($node->{value} eq 'unsigned short') {
			$node->{cpp_name} = "UShort";
		} elsif ($node->{value} eq 'long') {
			$node->{cpp_name} = "Long";
		} elsif ($node->{value} eq 'unsigned long') {
			$node->{cpp_name} = "ULong";
		} elsif ($node->{value} eq 'long long') {
			$node->{cpp_name} = "LongLong";
		} elsif ($node->{value} eq 'unsigned long long') {
			$node->{cpp_name} = "ULongLong";
		} else {
			warn __PACKAGE__,"::visitNameBasicType (IntegerType) $node->{value}.\n"
		}
	} elsif ($node->isa('CharType')) {
		$node->{cpp_name} = "Char";
	} elsif ($node->isa('WideCharType')) {
		$node->{cpp_name} = "WChar";
	} elsif ($node->isa('BooleanType')) {
		$node->{cpp_name} = "Boolean";
	} elsif ($node->isa('OctetType')) {
		$node->{cpp_name} = "Octet";
	} elsif ($node->isa('AnyType')) {
		$node->{cpp_name} = "Any";
		$node->{cpp_has_var} = 1;
	} elsif ($node->isa('ObjectType')) {
		$node->{cpp_name} = "Object";
		$node->{cpp_has_ptr} = 1;
	} elsif ($node->isa('ValueBaseType')) {
		$node->{cpp_name} = "ValueBase";	# ???
		$node->{cpp_has_ptr} = 1;			# ???
	} else {
		warn __PACKAGE__,"::visitNameBasicType INTERNAL ERROR (",ref $node,").\n"
	}
}

#
#	3.11.2	Constructed Types
#
#	3.11.2.1	Structures
#

sub visitNameStructType {
	my $self = shift;
	my($node) = @_;
	return if (exists $node->{cpp_ns});
	$node->{cpp_ns} = $self->_get_ns($node);
	$node->{cpp_name} = $self->_get_name($node);
	$node->{cpp_has_var} = 1;
	foreach (@{$node->{list_value}}) {
		$self->_get_defn($_)->visitName($self);		# single or array
	}
}

sub visitNameArray {
	my $self = shift;
	my($node) = @_;
	$node->{cpp_name} = $self->_get_name($node);
	$self->_get_defn($node->{type})->visitName($self);
}

sub visitNameSingle {
	my $self = shift;
	my($node) = @_;
	$node->{cpp_name} = $self->_get_name($node);
	$self->_get_defn($node->{type})->visitName($self);
}

#	3.11.2.2	Discriminated Unions
#

sub visitNameUnionType {
	my $self = shift;
	my($node) = @_;
	return if (exists $node->{cpp_ns});
	$node->{cpp_ns} = $self->_get_ns($node);
	$node->{cpp_name} = $self->_get_name($node);
	$node->{cpp_has_var} = 1;
	$self->_get_defn($node->{type})->visitName($self);
	foreach (@{$node->{list_expr}}) {
		$_->visitName($self);			# case
	}
}

sub visitNameCase {
	my $self = shift;
	my($node) = @_;
	foreach (@{$node->{list_label}}) {
		$_->visitName($self);			# default or expression
	}
	$node->{element}->visitName($self);
}

sub visitNameDefault {
	# empty
}

sub visitNameElement {
	my $self = shift;
	my($node) = @_;
	$self->_get_defn($node->{value})->visitName($self);		# single or array
}

#	3.11.2.4	Enumerations
#

sub visitNameEnumType {
	my $self = shift;
	my($node) = @_;
	$node->{cpp_ns} = $self->_get_ns($node);
	$node->{cpp_name} = $self->_get_name($node);
	foreach (@{$node->{list_expr}}) {
		$_->visitName($self);			# enum
	}
}

sub visitNameEnum {
	my $self = shift;
	my($node) = @_;
	$node->{cpp_name} = $self->_get_name($node);
}

#
#	3.11.3	Template Types
#
#	See	1.13	Mapping for Sequence Types
#

sub visitNameSequenceType {
	my $self = shift;
	my($node, $name) = @_;
	return if (exists $node->{cpp_ns});
	$node->{cpp_ns} = $self->_get_ns($node);
	my $type = 	$self->_get_defn($node->{type});
	$type->visitName($self);
	unless (defined $name) {
		$name = '_seq_' . $type->{cpp_name};
		if (exists $node->{max}) {
			$name .= '_' . $node->{max}->{value};
			$name =~ s/\+//g;
		}
	}
	$node->{cpp_name} = $name;
}

#
#	See	1.7		Mapping for String Types
#

sub visitNameStringType {
	my $self = shift;
	my($node) = @_;
	$node->{cpp_ns} = "CORBA";
	$node->{cpp_name} = "String";
}

#
#	See	1.8		Mapping for Wide String Types
#

sub visitNameWideStringType {
	my $self = shift;
	my($node) = @_;
	$node->{cpp_ns} = "CORBA";
	$node->{cpp_name} = "WString";
}

#
#
#

sub visitNameFixedPtType {
	my $self = shift;
	my($node) = @_;
	my $name = "Fixed";
	$node->{cpp_ns} = "CORBA";
	$node->{cpp_name} = $name;
}

sub visitNameFixedPtConstType {
	my $self = shift;
	my($node) = @_;
	my $name = "Fixed";
	$node->{cpp_ns} = "CORBA";
	$node->{cpp_name} = $name;
}

#
#	3.12	Exception Declaration
#

sub visitNameException {
	my $self = shift;
	my($node) = @_;
	return if (exists $node->{cpp_ns});
	$node->{cpp_ns} = $self->_get_ns($node);
	$node->{cpp_name} = $self->_get_name($node);
	foreach (@{$node->{list_value}}) {
		$self->_get_defn($_)->visitName($self);		# single or array
	}
}

#
#	3.13	Operation Declaration
#


sub visitNameOperation {
	my $self = shift;
	my($node) = @_;
	$node->{cpp_ns} = $self->_get_ns($node);
	$node->{cpp_name} = $self->_get_name($node);
	$self->_get_defn($node->{type})->visitName($self);
	foreach (@{$node->{list_param}}) {
		$_->visitName($self);			# parameter
	}
}

sub visitNameParameter {
	my $self = shift;
	my($node) = @_;
	$node->{cpp_name} = $self->_get_name($node);
	$self->_get_defn($node->{type})->visitName($self);
}

sub visitNameVoidType {
	my $self = shift;
	my($node) = @_;
	$node->{cpp_name} = "void";
}

#
#	3.14	Attribute Declaration
#

sub visitNameAttribute {
	my $self = shift;
	my($node) = @_;
	$node->{_get}->visitName($self);
	$node->{_set}->visitName($self) if (exists $node->{_set});
}

#
#	3.15	Repository Identity Related Declarations
#

sub visitNameTypeId {
	# empty
}

sub visitNameTypePrefix {
	# empty
}

#
#	3.16	Event Declaration
#

#
#	3.17	Component Declaration
#

sub visitNameProvides {
	# C++ mapping is aligned with CORBA 2.3
	my $self = shift;
	my($node) = @_;
	$node->{cpp_ns} = $self->_get_ns($node);
	$node->{cpp_name} = $self->_get_name($node);
}

sub visitNameUses {
	# C++ mapping is aligned with CORBA 2.3
	my $self = shift;
	my($node) = @_;
	$node->{cpp_ns} = $self->_get_ns($node);
	$node->{cpp_name} = $self->_get_name($node);
}

sub visitNamePublishes {
	# C++ mapping is aligned with CORBA 2.3
	my $self = shift;
	my($node) = @_;
	$node->{cpp_ns} = $self->_get_ns($node);
	$node->{cpp_name} = $self->_get_name($node);
}

sub visitNameEmits {
	# C++ mapping is aligned with CORBA 2.3
	my $self = shift;
	my($node) = @_;
	$node->{cpp_ns} = $self->_get_ns($node);
	$node->{cpp_name} = $self->_get_name($node);
}

sub visitNameConsumes {
	# C++ mapping is aligned with CORBA 2.3
	my $self = shift;
	my($node) = @_;
	$node->{cpp_ns} = $self->_get_ns($node);
	$node->{cpp_name} = $self->_get_name($node);
}

#
#	3.18	Home Declaration
#

sub visitNameFactory {
	# C++ mapping is aligned with CORBA 2.3
	my $self = shift;
	my($node) = @_;
	$node->{cpp_ns} = $self->_get_ns($node);
	$node->{cpp_name} = $self->_get_name($node);
	foreach (@{$node->{list_param}}) {
		$_->visitName($self);			# parameter
	}
}

sub visitNameFinder {
	# C++ mapping is aligned with CORBA 2.3
	my $self = shift;
	my($node) = @_;
	$node->{cpp_ns} = $self->_get_ns($node);
	$node->{cpp_name} = $self->_get_name($node);
	foreach (@{$node->{list_param}}) {
		$_->visitName($self);			# parameter
	}
}

1;

