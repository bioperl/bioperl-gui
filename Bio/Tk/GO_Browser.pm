
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

  my $Textbox;
  my $GO;
    	
  # create new main window.
  my $mw = MainWindow->new(-title => "GO Ontology Browser");
    		
  # create new textbox with scrollbars
  $Textbox = $mw->Scrolled("Text", -background => "black")->pack(-fill => "both", -expand => 1);
    		
  # alternate method to create new textbox, NOT RECOMMENDED!!
  #$Textbox = $mw->Text(-background => "black")->pack; 			
    		
  # create new GO browser
  $GO = GO_Browser->new($Textbox, TopWindow => $mw);
    		
    			
  # set up binding of button-2 to retrieve information
    $Textbox->bind("<Button-2>" => sub {	
       my $acc = $GO->GOAcc;
       my $term = $GO->Term;
       my $def = $GO->Definition;
       print "Acc = $acc Term = $term Def = $def\n\n";
    });
    	
 }



=head2 DESCRIPTION and ACKNOWLEDGEMENTS

Fills a Tk::Text widget with a browsable display of the GO ontology (http://www.geneontology.org/).
Items in red are "branches", while items in green are "leaves" of the GO ontology tree.
Double-clicking branches moves you up and down the tree.  Middle-clicking on any element records the
clicked-upon term and definition (if available) and this event can be trapped by the top-level windowing
system to retrieve this info for whatever external application you are building.

Unlike previous versions, this browser connects directly to the GO ontology database.
Therefore it requires no pre-downloading and parsing of the XML files (halleluja!)

Because it is connecting "live" there is sometimes a small delay while the query is being
sent over the net.  The number of queries required for the browser
has been mitigated as much as possible by some clever left-joins
written by Dave Block (dblock@gene.pbi.nrc.ca).  Thanks Dave!

=head2 CONTACT

Mark Wilkinson (mwilkinson@gene.pbi.nrc.ca)

=head2 Options

 $GO = GO_Browser->new(
   $Textbox,          	# the Tk Text widget
   TopWindow => $mw,   # the top-level window (or undef)
   GO_IP => "headcase.lbl.gov",  # the IP address of your GO database
   GO_dbName => "go"   # the name of the GO database
 );

=head2 Methods

 $GO->GOAcc	# returns Accession number of the middle-clicked term
 $GO->Term   # returns the Term name of the middle-clicked term
 $GO->Definition  # returns the associated definition

=cut


package GO_Browser;

use strict;
use Tk;
use Tk::Text;
use Carp;
use DBI;

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
                  (	GOText 			=> [undef,			'read/write'],   # the text box
                    path_stack		=> [[], 			'read/write'],   # because there are multiple paths through the tree, record $key's leading to our current position
                    ObjectType		=> [undef, 			'read/write'],	 # this can be called from a Tk::Text widget, or a Tk::Scrolled("Text") widget, which affects the binding calls in showKeys
                  	Term			=> [undef, 			'read/write'],	 # the GO Ontology term just middle-clicked upon
                  	Definition		=> [undef, 			'read/write'],	 # the definition of the term just middle-clicked upon
                  	GOAcc			=> [undef, 			'read/write'],	 # the acc id of the term just middled-clicked upon
                  	TopWindow		=> [undef, 			'read/write'],
                  	dbh				=> [undef, 			'read/write'],
                  	GO_IP			=> ['headcase.lbl.gov', 'read/write'],
                  	GO_dbName		=> ['go',			'read/write'],
                  	child_query		=> [undef, 			'read/write'],   # compiled query for "are there children of this term" - used for coloring branches versus leaves
                  	level_query		=> [undef, 			'read/write'],   # compiled query for "what are the children of this term" - used to get teh children of a branch
                  	def_query		=> [undef, 			'read/write'],   # compiled query for "what is the definition of this term"
                  	
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

sub dbAccess {
    my ($self) = @_;
    my $GO_IP = $self->GO_IP;
    my $GO_dbName = $self->GO_dbName;
	my ($dsn) = "DBI:mysql:$GO_dbName:$GO_IP";
	my $dbh = DBI->connect($dsn,undef,undef, {RaiseError => 1})or die "can't connect to database";
	return $dbh;
}


sub new{
	my ($caller, $text, %args) = @_;
	my ($GO);
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

    my $dbh = $self->dbAccess;
    $self->dbh($dbh);


    $self->GOText($text);  # set an internal reference to the text-box which will hold the browser.
    $self ->ObjectType(((ref($text) eq "Tk::Text")?"Text":"Scrolled")); # set object type to Text or Scrolled widget (Scrolled is actually a Tk::Frame object)
	
	$self->level_query($self->dbh->prepare("select
											definition,
											child.acc,
											child.name,
											count(term2.term1_id)
											from term as parent,
											term as child,
											term2term as relation
											left join
												term_definition as def
												on def.term_id= child.id
												left join
													term2term as term2
													on child.id=term2.term1_id
													where
													parent.acc = ? and
													parent.id = relation.term1_id and
													child.id = relation.term2_id
													group by child.acc"));	
	$self->showKeys("GO Ontology", $self->query_root);       # show the keys at root level

    return $self;                     # return handle to self
}

sub query_root {  # query the root level
	my ($self) = @_;
	
	my $start_qu = $self->dbh->prepare("select
										definition,
										parent.acc,
										child.acc,
										child.name,
										count(term2.term1_id)
										from term as parent,
										term as child,
										term2term as relation
											left join
											term_definition as def
											on
											def.term_id = child.id
												left join
												term2term as term2
												on child.id=term2.term1_id
												where
												parent.type = 'root' and
												parent.id = relation.term1_id and
												child.id = relation.term2_id
												group by child.acc
											");
	$start_qu->execute;
	my %GO_hash;
	my ($def, $parent, $acc, $term, $children, $root_acc);
	while (($def, $parent, $acc, $term, $children) = $start_qu->fetchrow_array){
		$root_acc = $parent;
		$GO_hash{$acc} = [$term, $def, $children];    # hard coded that they have children
	}
	return ($root_acc, \%GO_hash);
}


sub query_level {
	my ($self, $parent_acc) = @_;
	
	$self->level_query->execute($parent_acc);
	my %GO_hash;
	while (my ($def, $acc, $term, $children) = $self->level_query->fetchrow_array){
		$GO_hash{$acc} = [$term, $def, $children];
	}
	return ($parent_acc, \%GO_hash);
}

sub showKeys {
	my ($self, $parentterm, $parent_acc, $GO_hashref) = @_;    # hash is {acc}={term} where acc is eg. "8150", which is effectively "O:0008150" in the XML docs
	
	my %GO_hash = %{$GO_hashref};    # get the hash of things to display
	
	my $Text = $self->GOText;       # get the text-box reference
	$Text->configure(-state => "normal");  # empty it and make it writable
	$Text->delete("1.0", "end");
	
	$Text->insert("end", "/                         \n", ["root"]);     # make the '/' root level symbol
   	$Text->tagConfigure("root", -foreground => "yellow");  				# TO GO TO ROOT
   	$Text->tagBind("root", "<Double-Button-1>",                         # bind the double-click
   			sub {undef $self->{path_stack};                             # delete everything from the stack
   				$self->showKeys("GO Ontology", $self->query_root);      # refresh the browser with the root contents
   				$self->TopWindow->configure(-title => "GO Ontology");   # configure the title
   				$self->TopWindow->update;
   			});
	
	unless ($#{$self->{path_stack}} < 0){                                   # IF THERE IS NO TREE TO MOVE UP THEN DONT DO THIS
		$Text->insert("end", "../                        \n", ["parent"]);	# TO MOVE UP THE TREE
		$Text->tagConfigure("parent", -foreground => "yellow");
      	$Text->tagBind("parent", "<Double-Button-1>",
      			sub {my $grandterm = shift @{$self->{path_stack}};   	# take off of the stack the verbose TERM of the parent,
      				 my $grandparent = shift @{$self->{path_stack}};    # take off of the stack the Acession number of the parent,
      				
      				$self->showKeys($grandterm, $self->query_level($grandparent));  # then call this routine with the parents address
      				$self->TopWindow->configure(-title => $grandterm);
      				$self->TopWindow->update;
      				}
      			);
   	}
   	
   	
	foreach my $acc(keys %GO_hash){					# ask for the sub-level keys--> there are always two:  term and definition
			
			my ($term, $def, $children) = @{$GO_hash{$acc}};  # take the term phrase of the sub-level
			$term .= "\n";
			$Text->insert('end', $term, [$acc]);           # print it,and tag it with its key GO:nnnnnn
			
			$def = "No Definition Available" if (!$def);
			
			if ($children > 0){	                                 # if this term has children then it is not a leaf
				$Text->tagConfigure($acc, -foreground => "red"); # if it is not a leaf, then make it red
				$Text->tagBind($acc, "<Double-Button-1>",
						sub {                                   # if it is double-clicked, then
							unshift @{$self->{path_stack}}, $parent_acc;  # stick this parent accession number onto the stack for backing up purposes
							unshift @{$self->{path_stack}}, $parentterm;  # stick this parent TERM onto the stack
							chomp $term;                                  # remove the newline character we added
							$self->showKeys($term, $self->query_level($acc));  	# then call the routine using this child as the next root
						 	$self->TopWindow->configure(-title => $term);$self->TopWindow->update;
						 }
						);
			} else {
				$Text->tagConfigure($acc, -foreground => "green");  # if it is a leaf, then color it green
			}
			
						
			$Text->tagBind($acc, "<Button-2>",                      # bind the middle button
						sub {
							$self->GOAcc($acc);                     # encapsulate the data
							$self->Term($term);                     # this can be obtained from outside of the script
							$self->Definition($def)}
						);
			
			
			if ($self->ObjectType eq "Scrolled"){     # use this if called as a Scrolled text widget
				my @bindings = $Text->Subwidget("text")->bindtags();
				shift @bindings;  # get rid of the Tk::Text binding itself to prevent highlighting of the sequence
				unshift @bindings, $acc;
				
				$Text->Subwidget("text")->bindtags(\@bindings);
			} else {									# use this if called as a normal text widget
				$Text->bindtags(['all',
								'.',
								$acc,
								'parent',               # changed the order of binding
								'root', '.text',]); 	# because the text-box itself will respond to
			}                                           # double-clicks by highlighting the entire text!
			
			# put baloon-definitions here - not yet implemented
			#$Text->tagBind($key, "<Enter>")
	} # end of foreach my $acc
}



1;

