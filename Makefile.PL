use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'CORBA::Cplusplus',
    'VERSION_FROM'  => 'include.pm',
    'ABSTRACT'      => 'IDL compiler to C++',
    'PREREQ_PM'     => {
                        'CORBA::IDL::node'  => 2.20,
                        'CORBA::C::include' => 2.20
    },
    'PM'            => {
                        'include.pm'    => '$(INST_LIBDIR)/Cplusplus/include.pm',
                        'literal.pm'    => '$(INST_LIBDIR)/Cplusplus/literal.pm',
                        'name.pm'       => '$(INST_LIBDIR)/Cplusplus/name.pm',
                        'type.pm'       => '$(INST_LIBDIR)/Cplusplus/type.pm',
    },
    'EXE_FILES'     => ['idl2cpp.pl'],
    'AUTHOR'        => "Francois PERRAD (francois.perrad\@gadz.org)",
    'dist'          => {
                        'COMPRESS'      => 'gzip',
                        'SUFFIX'        => '.gz',
    },
);
