
=head2 NAME

Bio::Tk::GO_Browser.pm - Simplistic browser for GO ontology terms


=head2 AUTHORS

Mark Wilkinson (mwilkinson@gene.pbi.nrc.ca)
Plant Biotechnology Institute, National Research Council of Canada.
Copyright (c) National Research Council of Canada, October, 2000.

=head2 DISCLAIMER

Anyone who intends to use and uses this software and code acknowledges and
agrees to the following: The National Research Council of Canada (herein "NRC")
disclaims any warranties, expressed, implied, or statutory, of any kind or
nature with respect to the software, including without limitation any warranty
or merchantability or fitness for a particular purpose.  NRC shall not be liable
in any event for any damages, whether direct or indirect,
consequential or incidental, arising from the use of the software.

=head2 SYNOPSIS

 use GO_Browser;
 use Tk;
 use strict;

 Begin();
 MainLoop;

 sub Begin {

	# un-comment the line below if ontology XML files have NOT already been parsed
	# this must be done the first time you run this module, and need not be run again
	# unless you download newer versions of the XML files.
	#
	#  &ParseOntology;
	#
	# =================================================
		
 	my $Textbox;
 	my $GO;
    	
 	foreach my $section('component', 'process', 'function'){   # each of the current GO ontology sections
			# create new main window.
			# NOTE multiple browers must exists in different main windows
			# if the binding of the middle button is to function correctly.  If that is
			# not required, then this line can go outside of the foeach loop to make a single
			# frame with all GO browsers packed together.
 		my $mw = MainWindow->new();
    		
 			# create new textbox with scrollbars and relevant pack options
 		$Textbox->{$section} = $mw->Scrolled("Text", -background => "black")->pack(-expand => 1, -fill => "both");
    		
 			# alternate method to create new textbox, NOT RECOMMENDED!!  (Hard to intercept the double-clicks before they highlight the text!!)
 			#$Textbox->{$section} = $mw->Text(-background => "black")->pack; 			
    		
 			# create new GO browser, send it a reference to the MainWindow so that it can send info to title-bar.
 		$GO->{$section} = GO_Browser->new($Textbox->{$section}, $section, TopWindow => $mw);
    		
 			# check for failure
 		if ($GO->{$section} == 0){
 			print "\n\nBrowser reports unknown ontology type for $section\n\n";
 			next
 		} elsif ($GO->{$section} == -1){
 			print "\n\nBrowser unable to locate parsed ontology file for $section\n\n";
 			next
 		} elsif ($GO->{$section} == -2){
 			print "\n\nBrowser unable to instantiate in this type of Tk widget.  Must be Text or Scrolled\n\n";
 			next
 		}
    	
 			# set up binding of button-2 to retrieve information
 		$Textbox->{$section}->bind("<Button-2>" =>
 			sub {my $term = $GO->{$section}->Term;
 				my $def = $GO->{$section}->Definition;
 				print "Term = $term Def = $def\n\n";
 			});
 	}
 }

 sub ParseOntology {
    	
 	# do the initial parsing of the GO ontology XML files
 	# these files are available from http://www.geneontology.org/
 	# this routine must be run *once* before the GO browser will function.

 	# == FILL /home/user/full/path with the full path to your XM files ==
 	
 	my $ontology = GO_Browser->parseOntologyFile("/home/user/full/path/component.xml", "component");
 	if ($ontology == 0){print "\nparse fail - component ontology type not known\n\n"; return 0}
 	if ($ontology == -1){print "\nparse fail - component ontology XML file not found\n\n"; return 0}
    	
 	$ontology = GO_Browser->parseOntologyFile("/home/user/full/path/process.xml", "process");
 	if ($ontology == 0){print "\nparse fail - process ontology type not known\n\n"; return 0}
 	if ($ontology == -1){print "\nparse fail - process ontology XML file not found\n\n"; return 0}
    	
 	$ontology = GO_Browser->parseOntologyFile("/home/user/full/path/function.xml", "function");
 	if ($ontology == 0){print "\nparse fail - function ontology type not known\n\n"; return 0}
 	if ($ontology == -1){print "\nparse fail - function ontology XML file not found\n\n"; return 0}
    	
 	undef $ontology;
 }


=head2 DESCRIPTION and ACKNOWLEDGEMENTS

Fills a Tk::Text widget with a browsable display of the GO ontology (http://www.geneontology.org/).
Items in red are "branches", while items in green are "leaves" of the GO ontology tree.
Double-clicking branches moves you up and down the tree.  Middle-clicking on any element records the
clicked-upon term and definition (if available) and this event can be trapped by the top-level windowing
system to retrieve this info for whatever external application you are building.

This has only been tried and tested on the XML files that were available on Jan 31, 2001.  I hope that
it is stable enough to parse newer or older versions, but as these ontology XML files are in a state of
flux at the moment I can't promise anything.

Parsing takes about 10-15 minutes, and must be done only once.  The data is then stored in three files which,
by default, live in the same folder as this script.  The files end in the extension .gob, which generally
represents how I feel about them.

Loading of all three .gob files takes a total of ~2 seconds (single Celeron 500MHz).

Please send all complaints to me, but remember, I never promised the world.  This is just a hack :-)


=head2 CONTACT

Mark Wilkinson (mwilkinson@gene.pbi.nrc.ca)


=cut


package GO_Browser;

use strict;
use Tk;
use Tk::Text;
use Carp;
require XML::Simple;
#use Tk::widgets qw(Balloon);
use Storable;
use vars qw($AUTOLOAD);
Tk::Widget->Construct('GO_Browser');

{
	#Encapsulated class data
	
	#___________________________________________________________
	#ATTRIBUTES
    my %_attr_data = #     				DEFAULT    	ACCESSIBILITY
                  (	process_root 	=> ["GO:0008150", 	'read/write'],   # the root GO numbers for the three ontologies
                    function_root 	=> ["GO:0003674", 	'read/write'],   #    "
                    component_root 	=> ["GO:0005575", 	'read/write'],   #    "
                    instance_root 	=> [undef, 			'read/write'],   # which of the above root files do we use in this instance
                    GOText 			=> [undef,			'read/write'],   # the text box
                    GOpath			=> ["./", 			'read/write'],   # the path to the GOxxx.wb files, requires trailing slash.
                    GO				=> [undef, 			'read/write'],   # holds the full imported GO ontology hash
                    path_stack		=> [[], 			'read/write'],   # because there are multiple paths through the tree, record $key's leading to our current position
                    ObjectType		=> [undef, 			'read/write'],	 # this can be called from a Tk::Text widget, or a Tk::Scrolled("Text") widget, which affects the binding calls in showKeys
                  	Term			=> [undef, 			'read/write'],	 # the GO Ontology term just middle-clicked upon
                  	Definition		=> [undef, 			'read/write'],	 # the definition of the term just middle-clicked upon
                  	TopWindow		=> [undef, 			'read/write'],
                  	
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
	    if ($_[1]) { $_[0]->{$attr} = $_[1] }
	    return $_[0]->{$attr};
	};    ### end of created subroutine

###  this is called first time only
	if ($newval) {
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


sub new{
	my ($caller, $text, $ontology, %args) = @_;
	my ($GO);
	return 0 if (($ontology ne "process") && ($ontology ne "function") && ($ontology ne "component"));
	return -2 if ((ref($text) ne "Tk::Text") && (ref($text) ne "Tk::Frame"));
	
	my $caller_is_obj = ref($caller);
    my $class = $caller_is_obj || $caller;
    my $self = $text;

    $self = bless {}, $class;

    foreach my $attrname ( $self->_standard_keys ) {
    	if (exists $args{$attrname}) {
		$self->{$attrname} = $args{$attrname} }
    elsif ($caller_is_obj) {
		$self->{$attrname} = $caller->{$attrname} }
    else {
		$self->{$attrname} = $self->_default_for($attrname) }
    }


    $self->GOText($text);  # set an internal reference to the text-box which will hold the browser.
    $self ->ObjectType(((ref($text) eq "Tk::Text")?"Text":"Scrolled")); # set object type to Text or Scrolled widget (Scrolled is actually a Tk::Frame object)
	
	my $GOpath = $self->{GOpath};
	
    my $gofile;
	if ((-e $GOpath . "GOprocess.gob") && ($ontology eq "process")){      # set which file to open
		$gofile = $GOpath . "GOprocess.gob";
	}
	elsif ((-e $GOpath . "GOfunction.gob") && ($ontology eq "function")){
		$gofile = $GOpath . "GOfunction.gob";	
	}
	elsif ((-e $GOpath . "GOcomponent.gob") && ($ontology eq "component")){
		$gofile = $GOpath . "GOcomponent.gob";	
	}
    else {return -1}  # wb-parsed function does not exist yet

    $GO = retrieve($gofile);  # this is a thaw of the frozen data

    #  **************  store the parsed GO information in self->GO
    $self->GO($GO);
    # ************************************************************

    (($ontology eq "process" && ($self->instance_root($self->process_root))) ||    # set this instance of GO:nnn "root" value to the
    ($ontology eq "function" && ($self->instance_root($self->function_root))) ||   # encapsulated default for the ontology file
    ($ontology eq "component" && ($self->instance_root($self->component_root))));

    $self->showKeys($self->instance_root);  # show the keys at this level

    return $self;                        # return handle to self
}

sub showKeys {    # this subroutine prints out the **CHILDREN** of the Key-level passed in $GOkey
	my ($self, $GOkey) = @_;    # $GOkey is eg. "GO:0008150"
	my $ThisLevel = $self->GO->{$GOkey};  # get the entry for this level now, for later clarity
	
	my $Text = $self->GOText;       # and is abstracted so that at any level you can query the sub level keys
	$Text->configure(-state => "normal");
	my $found; # a flag if there are sub-level keys available
	$Text->delete("1.0", "end");
	$Text->insert("end", "/                         \n", ["root"]);
	unless ($#{$self->{path_stack}} < 0){                                   # IF THERE IS NO TREE TO MOVE UP THEN DONT DO THIS
		$Text->insert("end", "../                        \n", ["parent"]);	# TO MOVE UP THE TREE
		$Text->tagConfigure("parent", -foreground => "yellow");
      	$Text->tagBind("parent", "<Double-Button-1>",
      			sub {my $parent = shift @{$self->{path_stack}};   	# take off of the stack the GO:NNN of the parent,
      				if ($self->TopWindow){$self->TopWindow->configure(-title => $self->GO->{$parent}->{"term"})};
      				$self->showKeys($parent);                        # then call this routine with the parents address
      				}
      			);
   	}
   	
   	$Text->tagConfigure("root", -foreground => "yellow");  	# TO GO TO ROOT
   	$Text->tagBind("root", "<Double-Button-1>",
   			sub {$self->showKeys($self->instance_root)} # simply take the root address from the encapsulated data and call this routine
   			);
   	
	foreach my $child(keys(%{$ThisLevel})){					# ask for the sub-level keys--> there are always two:  term and definition
		if ($child ne "term" && $child ne "definition"){  	# ignore the term and def of the *current* level
			if ($child eq "genes"){
				if ($#{$ThisLevel->{"genes"}} == -1){
					next;  # if there are no asscociated genes then skip this entry
				} else {
					my @genes = @{$ThisLevel->{"genes"}};	# get the array of genes
					foreach my $gene(@genes){
						chomp $gene;  # ensure one and only one newline character
						$Text->insert('end', $gene . "\n", [$gene]);           # print it,and tag it with its key GO:nnnnnn
					    $Text->tagBind($gene, "<Button-2>",
									sub {
										$self->Term($gene);
										$self->Definition("undefined")}
									);
						$Text->tagConfigure($gene, -foreground => "lightblue"); 			
					}
					next;
				}
			}
			$found = 1;    								# flag that there was a sub-level key found
			my $term = $ThisLevel->{$child}->{"term"} . "\n";  # take the term phrase of the sub-level
			$Text->insert('end', $term, [$child]);           # print it,and tag it with its key GO:nnnnnn
			my $def =  $ThisLevel->{$child}->{"definition"}?$ThisLevel->{$child}->{"definition"}:"No Definition Available"; # take the def phrase of the sub level
			
			my @ChildsChildren = (keys %{$ThisLevel->{$child}});	# now query if this child itself has children, or if it is a "leaf"
			if ($#ChildsChildren > 2){       # if it has more than the default number of tags (3)
				$Text->tagConfigure($child, -foreground => "red"); # if it is not a leaf, then make it red
				$Text->tagBind($child, "<Double-Button-1>",
						sub {                                   # if it is double-clicked, then
							unshift @{$self->{path_stack}}, $GOkey;  # stick this parent onto the stack to come back to this point later
							if ($self->TopWindow){$self->TopWindow->configure(-title => $self->GO->{$child}->{"term"})};
      						$self->showKeys($child);  # then call the routine using this child as the next root
						 }
						);
			} else {
				$Text->tagConfigure($child, -foreground => "green");  # if it is a leaf, then color it green
			}
			
						
			$Text->tagBind($child, "<Button-2>",
						sub {
							$self->Term($term);
							$self->Definition($def)}
						);
			
			if ($self->ObjectType eq "Scrolled"){     # use this if called as a Scrolled text widget
				my @bindings = $Text->Subwidget("text")->bindtags();
				shift @bindings;  # get rid of the Tk::Text binding itself to prevent highlighting of the sequence
				unshift @bindings, $child;
				
				$Text->Subwidget("text")->bindtags(\@bindings);
			} else {									# use this if called as a normal text widget
				$Text->bindtags(['all',
								'.',
								$child,
								'parent',               # changed the order of binding
								'root', '.text',]); 	# because the text-box itself will respond to
			}                                           # double-clicks by highlighting the entire text!
			
			# put baloon-definitions here - not yet implemented
			#$Text->tagBind($key, "<Enter>")
		
		}	# end of IF
	} # end of foreach my $child
}


sub parseOntologyFile {

	my ($caller, $filename, $type) = @_;    # caller will normally be an uninstantiated GO_browser, $filename is the full path, $type is the ontology type
    my $xs = new XML::Simple();

    my $GoPath = (ref($caller) && $caller->{GOpath})?$caller->{GOpath}:"./";  # if caller is an object try to extract the path, otherwise use the default

    return 0 if (!  (($type eq "function") || ($type eq "component") || ($type eq "process"))  ); # must be a valid ontology type

    if (-e $filename){open IN, $filename or die "\nparser could not open the XML ontology file for first parsing pass\n";}
    else {return -1}

    open OUT, ">$GoPath" . "tmpGOfile.remove_me" or die "\nparser could not open temporary output file $!\n";
    while (my $line = <IN>){
    	if ($line =~ /^\s*\!/){print "deleted:   $line\n\n"; next}   # get rid of the GO comment lines which begin with an !
    	if ($line =~ /[^<>:;\(\)\,\."'!\/\+\-\=%\?\[\]\w\s\d]/){print "modified:   $line";$line =~ s/[^<>:;\(\)\,\."'!\/\+\-\=%\w\s\d]//g;print "NEW:   $line\n\n"}  # get rid of any unusual characters... and the GO ontology XML files contain all sorts of invisible non-whitespace characters...
    	if ($line =~ /<up>/){print "FormatTagRemoved:   $line"; $line =~ s/<up>//g;print "NEW:   $line\n\n"}   # these are superscript tags that XML::Parser cant interpret correctly
    	if ($line =~ /<\/up>/){print "FormatTagRemoved:   $line"; $line =~ s/<\/up>//g;print "NEW:   $line\n\n"}
    	if ($line =~ /<down>/){print "FormatTagRemoved:   $line"; $line =~ s/<down>//g;print "NEW:   $line\n\n"} # as above, but subscript tags
    	if ($line =~ /<\/down>/){print "FormatTagRemoved:   $line"; $line =~ s/<\/down>//g;print "NEW:   $line\n\n"}
    	
    	while ($line =~ /(.*?)<([\d\w])>(.*)/){   # get rid of invalid XML which existed in early versions of GO ontology
    		print "BadXML:  $line";               # they seem to use angle brackets instead of normal brackets in some cases, resulting in unmatched tags
    		$line = $1 . "($2)" . $3;
    		print "NEW:     $line\n\n"
    	}
    	print OUT $line;                          # print the cleaned up line to the temp fie
    }
    close IN;
    close OUT;
 	
    $filename = "$GoPath" . "tmpGOfile.remove_me";

    my $ref = $xs->XMLin($filename);              # XMLin throws an error if this file is not available.
    my $GO;  # this variable holds the pruned and self-referencing hash of GO terms

    foreach my $key(keys(%{$ref->{"go:term"}})){
    	#print "working on key $key\n";
    	my $relation;
    	my $thisentry = $ref->{"go:term"}->{$key};
    	if ($thisentry->{"go:isa"}){                    # terms at the moment have "isa" or "partof" subtags.
    		$relation = "go:isa";
    	} elsif ($thisentry->{"go:partof"}){
    		$relation = "go:partof";
    	} else {print "================================>> new GO term found $key\n"    # warn if there is a unknown tag
    	}
    	my ($def, $term);	
    	my $assoc;  # hash that will contain the association data
    	    	
    	#get rid of downstream "junk"
    	#if ($thisentry->{"go:association"}){delete $thisentry->{"go:association"}}     # all heavily detailed data is completely removed from the hash to save time and space
    	    	
    	if (ref $thisentry->{"go:definition"} eq "ARRAY"){
    		$def = $thisentry->{"go:definition"}->[0]; #  I have no idea why this returns an array sometimes...???
    		#print "$def\n";
    	} else {
    		$def = $thisentry->{"go:definition"};
    		#print "$def\n";
    	}
    	$def = ($def)?$def:"No Definition Provided";
    	$def =~ s/\s\s//g; $def =~ s/^\s//;$def =~ s/\s$//;  # remove leading/trailing extra spaces
    	$def =~ s/\n//g;                     # remove newlines
    	
    	$term = $thisentry->{"go:name"};
    	$term =~ s/\s\s//g; $term =~ s/^\s//;$term =~ s/\s$//;  # remove leading/trailing extra spaces
    	$term =~ s/\n//g;                     # remove newlines
											# fill in the details about the child
    	$GO->{$key}->{"definition"} = $def; # each child is expected to have three reliable keys
    	$GO->{$key}->{"term"} = $term;      # so create them now.
    	$GO->{$key}->{"genes"} = [];        # (may not have any, so initialize an empty anon array)
    	
    	if ($thisentry->{"go:association"}){
    		my @thisass;
    		if (ref $thisentry->{"go:association"} eq "ARRAY"){
    			@thisass = @{$thisentry->{"go:association"}};
    		} else {
    			push @thisass, $thisentry->{"go:association"};
    		}
    		my @genes;
    		foreach my $ass(@thisass){
    			push @{$GO->{$key}->{"genes"}}, $ass->{"go:gene_product"}->{"go:symbol"};	
    			
    		}
    	}
    	
    	if (ref $thisentry->{$relation} eq "ARRAY"){    	# if there are multiple parents
    		foreach my $elem(@{$thisentry->{$relation}}){  # for each parent
    			my $parentkey = $elem->{"parent_id"};            # get the parent ID
    			$GO->{$parentkey}->{$key} = $GO->{$key};          # write a ref to this child in the parent
    	    }
    	} else {                                                   # single parents
    			my $parentkey = $thisentry->{$relation}->{"parent_id"}; # get the parent ID
    			$GO->{$parentkey}->{$key} = $GO->{$key};                 # write a ref to the child in the parent
    	}	

    }
    unlink $filename;   # delete the temporary file

    #print "got to end\n";
    #print "dumping data\n";

    my $OUTfilename = "GO" . $type . ".gob";      # create a predictable filename
    store \%{$GO}, "$GoPath" . "$OUTfilename";    # store in binary format
	return $GO
}

1;

