=head1 GO_Annotation

=head2 AUTHORS

Mark Wilkinson (mwilkinson@gene.pbi.nrc.ca)

=head2 DISCLAIMER

Anyone who intends to use and uses this software and code acknowledges and
agrees to the following: The National Research Council of Canada (herein "NRC")
disclaims any warranties, expressed, implied, or statutory, of any kind or
nature with respect to the software, including without limitation any warranty
or merchantability or fitness for a particular purpose.  NRC shall not be liable
in any event for any damages, whether direct or indirect,
consequential or incidental, arising from the use of the software.

=head2 SYNOPSIS

  use GO_Annotation;
  my $GO_annot = GO_Annotation->new(
    id => '8560',
    term => "biological_process",
    def => "this is a biological process"
    );

  my @refs1;
  my @refs2;

  push @refs1, "Wilkinson, et al., Development, 2000";
  push @refs1, "Schwarz-Sommer et al., EMBO-J, 2000";

  push @refs2, "test2";
  push @refs2, "test3";

  my $return = $GO_annot->addEvidence("TAS", \@refs1);
  if (!$return){print "addEvidence failed\n"}
  elsif ($return == -1){print "Invalid Evidence Code - no evidence added\n"}

  my $return = $GO_annot->addEvidence("IMP", \@refs1);

  my $return = $GO_annot->addReference("IMP", \@refs2);
  print "GO Accession: " . $GO_annot->GO_id . "  " . $GO_annot->term . "\n";
  print "Definition: " . $GO_annot->def . "\n";
  print "Evidence: \n";

  my %evidence = %{$GO_annot->evidence};

  foreach my $code(keys %evidence){
     print "\tEvidence Type: $code\n";
  	foreach my $ref(@{$evidence{$code}}){
        print "\t\tReference: $ref\n";
      }
   }
  print $GO_annot->gff2_attributes;

=head2 DESCRIPTION and ACKNOWLEDGEMENTS

Creates a GO annotation object. GO_Annotations have an id, term, definition,
a list of synonyms, and one or more evidence codes each of which may have
one or more references.  This object is NOT GO-database-aware, so you
are responsible for getting the correct id's, terms, and def's together!
Rather than creating these objects 'from scratch', It is advisable to
retrieve $GO_Annotation objects from a module such as
GO_Browser.pm, which extracts these elements from the GO database.


=head2 CONTACT

Mark Wilkinson (mwilkinson@gene.pbi.nrc.ca)

=cut


package GO_Annotation;

use strict;
use Carp;
use vars qw($AUTOLOAD);

{
	#Encapsulated class data
	
	#___________________________________________________________
	#ATTRIBUTES
    my %_attr_data = #     				DEFAULT    	ACCESSIBILITY
                  (
                  	id 	=>	[undef, 	'read/write'],
                  	def	=>	[undef,		'read/write'],
                  	term=>	[undef, 	'read/write'],
                  	synonyms => [undef, 	'read/write'],  # not currently supported
                  	evidence => [undef, 	'read/write'],
                  	GO_id => [undef, 	'read/write'],
                  	
                    );

   #_____________________________________________________________
    #METHODS, to operate on encapsulated class data

    # Is a specified object attribute accessible in a given mode
    sub _accessible  {
	my ($self, $attr, $mode) = @_;
	$_attr_data{$attr}[1] =~ /$mode/
    }

    # Classwide default value for a specified object attribute
    sub _default_for {
	my ($self, $attr) = @_;
	$_attr_data{$attr}[0];
    }

    # List of names of all specified object attributes
    sub _standard_keys {
	keys %_attr_data;
    }

}
sub AUTOLOAD {
    no strict "refs";
    my ($self, $newval) = @_;

    $AUTOLOAD =~ /.*::(\w+)/;

    my $attr=$1;
    if ($self->_accessible($attr,'write')) {

	*{$AUTOLOAD} = sub {
	    if (defined $_[1]) { $_[0]->{$attr} = $_[1] }
	    return $_[0]->{$attr};
	};    ### end of created subroutine

###  this is called first time only
	if (defined $newval) {
	    $self->{$attr} = $newval
	}
	return $self->{$attr};

    } elsif ($self->_accessible($attr,'read')) {

	*{$AUTOLOAD} = sub {
	    return $_[0]->{$attr} }; ### end of created subroutine
	return $self->{$attr}  }


    # Must have been a mistake then...
    croak "No such method: $AUTOLOAD";
}

=head3 new

  Usage: $GO_Annotation->new();
  Args: id => $id
        term => $term
        def => $def
        evidence => \@evidence
        GO_id => $GO_id
  Returns:  GO_annotation object
  Comments:  "id" is the integer part of the GO Accession number (eg. 8150)
             "GO_id" is the formatted GO Accession number (eg. GO:0008150)
             setting either one of these will set the other.

=cut


sub new {
	my ($caller, %args) = @_;
	
	my $caller_is_obj = ref($caller);
    my $class = $caller_is_obj || $caller;

    my $self = bless {}, $class;

    foreach my $attrname ( $self->_standard_keys ) {
    	if (exists $args{$attrname}) {
		$self->{$attrname} = $args{$attrname} }
    elsif ($caller_is_obj) {
		$self->{$attrname} = $caller->{$attrname} }
    else {
		$self->{$attrname} = $self->_default_for($attrname) }
    }
	if ($args{id}){
    	$self->id($args{id});
 	} elsif ($args{GO_id}){
 		$self->GO_id($args{GO_id});
 	}
    return $self;

}

=head3 id

  Usage: $GO_Annotation->id();
  Args: new id number (integer portion only)
  Returns:  id number (integer portion only)
  Comments:  gets/sets the id number

=cut

sub id {
	my ($self, $id) = @_;
	return ($self->{id}) if (!$id);
	return 0 if (!($id =~ /^\d{1,7}$/)); # from one to seven digits and nothing else will do!
	
	my $GO_id = sprintf "GO:%07u", $id;
	$self->{id} = $id;
	$self->{GO_id} = $GO_id;
	return $id;
}	

=head3 GO_id

  Usage: $GO_Annotation->GO_id();
  Args: new GO-formatted id number (eg. GO:0008150)
  Returns: current GO-formatted id number (eg. GO:0008150)
  Comments:  gets/sets the GO_id

=cut

sub GO_id {
	my ($self, $GO_id) = @_;
	return ($self->{GO_id}) if (!$GO_id);
	return 0 if (!($GO_id =~ /GO:\d{7}/));   # if they are trying to set it using an invalid string, then ignore the call
	
	my $id = ($GO_id =~ /GO:0*(\d+)/) && $1;  # get the number part of the identifier
	$self->{id} = $id;
	$self->{GO_id} = $GO_id;
	return $GO_id;
	
}

=head3 term

  Usage: $GO_Annotation->term();
  Args: scalar containing the new term string
  Returns: scalar containing the term string
  Comments:  gets/sets the GO term  (eg. apoptosis)

=cut

=head3 addEvidence

  Usage: $GO_Annotation->addEvidence($code, [\@refs]);
  Args: $code - one of IMP,IGI,ISS,IPI,IDA,IEP,IEA,TAS,NAS,NA
        \@refs - reference to an array of evidence strings
  Returns: 0 if incorrectly called, -1 if invalid code used
  Comments:  adds evidence code and optional associated references to the GO object.

=cut

sub addEvidence {
	my ($self, $code, $refs) = @_;
	return 0 if (!$code);
	return -1 if (!($code =~ /IMP|IGI|ISS|IPI|IDA|IEP|IEA|TAS|NAS|NA/));
	if (!(defined $self->evidence)){$self->evidence({})}
  	if (!(${$self->evidence}{$code})){
  		${$self->evidence}{$code} = undef
  	};
  	if ($refs){
  		push @{${$self->evidence}{$code}}, @{$refs}
	
  	};
	
	return 1;

}

=head3 addReference

  Usage: $GO_Annotation->addReference($code, \@refs);
  Args: $code - one of IMP,IGI,ISS,IPI,IDA,IEP,IEA,TAS,NAS,NA
        \@refs - reference to an array of evidence strings
  Returns: 0 if incorrectly called, -1 if invalid code used
  Comments:  adds reference(s) to existing evidence codes.

=cut

sub addReference {
	my ($self, $code, $refs) = @_;
	return 0 if (!$code || !$refs);
	return -1 if (!($code =~ /IMP|IGI|ISS|IPI|IDA|IEP|IEA|TAS|NAS|NA/));
	if (!(defined $self->evidence)){$self->evidence({})}
  	if (!(${$self->evidence}{$code})){
		${$self->evidence}{$code} = undef
	};
	push @{${$self->evidence}{$code}}, @{$refs};
	
	return 1;

}

=head3 gff2_attributes

  Usage: $GO_Annotation->gff2_attributes
  Args:
  Returns: GFF2 formatted attributes string
  Comments:  returns a string which could be used in a GFF2 attributes field.
            it look like... eg.

            ACC GO:0008150 ; EVID1 TAS "Wilkinson et al. 2000" ; EVID2 IMP "Schwarz-Sommer et al"

            where ACC is a reliable tag indicating Accession number, followed by the value
            EVID1, EVID2...EVIDn are pieces of evidence, followed by the evidence type, and the reference(s)

=cut

sub gff2_attributes {
	my ($self) = @_;
	my $gff = "ACC \"" . $self->GO_id . "\" ; ";
	my $c;
	my %evidence = %{$self->evidence};
	
	foreach my $code (keys %evidence){
		++$c;
		$gff .= "EVID$c " . $code;
		foreach my $ref(@{$evidence{$code}}){
			$gff .= " \"$ref\" ";
		}
		$gff .= " ; ";
	}
	$gff =~ /(.*);\s/;
	$gff = $1;
	return $gff;
}

=head3 evidence

  Usage: my $evidence_ref = $GO_Annotation->evidence();
         my %evidence = %{$GO_Annotation->evidence};
  Args:
  Returns: %evidence is a hash of {$code} = [$ref, $ref2, $ref3...]
           where $code is the evidence code and $ref's are
           strings resumably containing references to database
           entries or journal articles, or whatever.
  Comments:  retrieves the evidence from the annotation object

=cut

=head3 def

  Usage: $GO_Annotation->def();
  Args: scalar containing the new definition string
  Returns: scalar containing the definition string
  Comments:  gets/sets the definition

=cut

sub DESTROY {}

1;
