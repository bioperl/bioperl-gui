
=head2 NAME

Bio::Tk::GO_Browser.pm - Simplistic browser for GO ontology terms


=head2 AUTHORS

Mark Wilkinson (mwilkinson@gene.pbi.nrc.ca)
Plant Biotechnology Institute, National Research Council of Canada.
Version 1: Copyright (c) National Research Council of Canada, October, 2000.
Version 2: Copyright (c) National Research Council of Canada, March, 2001.

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
  my $frame = $mw->Frame()->pack(-fill => 'both', -expand => 1);  		

  # create new GO browser
  # NOTE that the browser is now created inside of a frame, instead of with a text widget
  $GO = GO_Browser->new($frame, TopWindow => $mw);
    		
    			
  # set up binding of button-2 to retrieve information
  # NOTE the difference in the binding call compared to version 1.0
  my $Annotation;
  $GO->GOText->bind("<Button-2>" => sub {
       $Annotation = $GO->Annotation; # retrieve the annotation object (see GO_Annotation.pm)
       my $acc = $Annotation->GO_id;
       my $term = $Annotation->term;
       my $def = $Annotation->def;
       print "Acc = $acc Term = $term Def = $def\n\n";
       });
    	
 }



=head2 DESCRIPTION and ACKNOWLEDGEMENTS

Fills a Tk::Frame widget with a browsable display of the GO ontology (http://www.geneontology.org/).
Items in red are "branches", while items in green are "leaves" of the GO ontology tree.
* Single-Clicking displays the definition of a term.
* Double-clicking branches moves you up and down the tree.
* Middle-clicking on any element records the
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
   $Frame,          	# the Tk Frame widget
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

use vars qw($AUTOLOAD);


{
	#Encapsulated class data
	
	#___________________________________________________________
	#ATTRIBUTES
    my %_attr_data = #     				DEFAULT    	ACCESSIBILITY
                  (	GOText 			=> [undef,			'read/write'],   # the text box
                    QueryText		=> [undef, 			'read/write'],   # the query box
                    DefText			=> [undef, 			'read/write'],   # the definition of the term
                    query_stack		=> [[], 			'read/write'],   # because there are multiple paths through the tree, record ->fetchall_arrayref's leading to our current position
                    ObjectType		=> [undef, 			'read/write'],	 # this can be called from a Tk::Text widget, or a Tk::Scrolled("Text") widget, which affects the binding calls in showKeys
                  	TopWindow		=> [undef, 			'read/write'],
                  	dbh				=> [undef, 			'read/write'],
                  	GO_IP			=> ['headcase.lbl.gov', 'read/write'],
                  	GO_dbName		=> ['go',			'read/write'],
                  	tree_query		=> [undef, 			'read/write'],   # compiled query to step down a branch to next node
                  	root_query		=> [undef, 			'read/write'],   # compiled query to go to root
                  	keyword_query	=> [undef, 			'read/write'],   # compiled query to search for a keyword
                  	Annotation		=> [undef, 			'read/write'],
                  	
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
	my $dbh = DBI->connect($dsn,undef,undef, {RaiseError => 1}) or die "can't connect to database";
	$dbh or die "\n\n GO-database connection failed \n\n";
	
	return $dbh;
}


sub new{
	my ($caller, $frame, %args) = @_;
	my ($GO);
	return -2 if ((ref($frame) ne "Tk::Frame"));
	
	my $caller_is_obj = ref($caller);
    my $class = $caller_is_obj || $caller;
    my $self = $frame;
    $self = bless {}, $class;


    # initialize object
    foreach my $attrname ( $self->_standard_keys ) {
    	if (exists $args{$attrname}) {
		$self->{$attrname} = $args{$attrname} }
    elsif ($caller_is_obj) {
		$self->{$attrname} = $caller->{$attrname} }
    else {
		$self->{$attrname} = $self->_default_for($attrname) }
    }
    #  OBJECT INITIALIZED

    # now fill it
    my $QueryFrame = $frame->Frame()->pack(-side => 'top', -fill => 'x');
    my $GOFrame = $frame->Frame()->pack(-side => 'top', -fill => 'both', -expand => 1);
    my $DefFrame = $frame->Frame()->pack(-side => 'top', -fill => 'both', -expand => 1);

    $QueryFrame->Label(-text => "Query Keywords", -background => 'white', -foreground => 'black')->pack(-side => 'left', -fill => 'x', -expand => 1);
	$self->QueryText($QueryFrame->Text(-background => 'blue', -foreground => 'white', -height => 1)->pack(-side => 'left', -fill => 'x', -expand => 1));
    $QueryFrame->Button(-text => "Search", -command => sub {$self->query_keywords})->pack(-side => 'right');
    $self->GOText($GOFrame->Scrolled("Text", -background => "black")->pack(-fill => "both", -expand => 1));
    $self->DefText($DefFrame->Scrolled("Text", -background => 'blue', -foreground => 'white',-height => 3, -wrap => 'word')->pack(-fill => 'both', -expand => 1));


    # retrieve the GO database handle
    my $dbh = $self->dbAccess;
    $self->dbh($dbh);

    # the line below *should* be deprecated now... but i am not entirely certain...
    # object tuype should always be Scrolled as far as I understand.  This
    # is only important w.r.t. the tweaking of bindings at the end of of sub showKeys{}
    $self ->ObjectType(((ref($self->GOText) eq "Tk::Text")?"Text":"Scrolled")); # set object type to Text or Scrolled widget (Scrolled is actually a Tk::Frame object)
	

	$self->_set_queries;  # this creates and pre-compiles all standard queries.  Search queries have to be generated "on the fly"
												
	$self->showKeys("GO Ontology", $self->query_root);  # show the keys at root level

    return $self;                     # return handle to self
}

sub query_root {  # query the root level.  This is just a quick way to get back to root using it's own SQL statement
	my ($self) = @_;
	my $variable = 'root';

	$self->root_query->execute($variable);  # a single variable, 'root' is effectively hard coded here
	my %GO_hash;
	my ($def, $acc, $term, $children);
	my @QueryResults = @{$self->root_query->fetchall_arrayref};
	foreach my $row(@QueryResults){
		($def, $acc, $term, $children) = @{$row};
		$GO_hash{$acc} = [$term, $def, $children];
	}
	
	return (\@QueryResults, \%GO_hash);
}


sub do_query {   # gets the query statement handle and the variable,
					# executes an arbitrary query, and then returns the result
	my ($self, $sth, $variables) = @_;
	my (@variables) = @{$variables};  # b.t.w. the first variable is *usually* the GO-term acc
	$sth->execute(@variables);        # execute the query sent
	my ($def, $acc, $term, $children);
	my @QueryResults = @{$sth->fetchall_arrayref};
	my %GO_hash;
	foreach my $row(@QueryResults){
		($def, $acc, $term, $children) = @{$row};
		$GO_hash{$acc} = [$term, $def, $children];
	}
	return (\@QueryResults, \%GO_hash);                             # return the hash, along with the variables that were used to create it
}                                                                     # these will be pushed onto a stack (or have been pulled off of a stack)

sub query_keywords {
	# this is called by typing search terms into the search box and clicking "search"
	# it queries the GO_term text, synonym text, and definition text
	# all matches are shown in the box
	# multiple keywords are combined with "OR" at the moment.
my $init_query = "select
					def.term_definition,
					child.acc,
					child.name,
					count(term2.term1_id)
					from term as parent,
					term as child,
					term2term as relation
						left join
						term_synonym as syn
						on syn.term_id = child.id
							left join
							term_definition as def
							on def.term_id = child.id
								left join
								term2term as term2
								on child.id = term2.term1_id ";
my $WHERE = "WHERE ";
my $query_param = "((def.term_definition Like ? OR
					syn.term_synonym Like ? OR
					child.name Like ?) AND
					parent.id = relation.term1_id and
					child.id = relation.term2_id) ";
my $GROUP_BY = " group by child.acc";

	my ($self) = @_;
	my $keywords = $self->QueryText->get('1.0', 'end'); # get the keywords
	chomp $keywords;                                    # get rid of \n
	$keywords =~ s/,/ /g;                               # get rid of commas (if any)
	my @keywords = split /\s+/, $keywords;              # split on space into individual keywords
	return if ($#keywords == -1); 						# exit if no search terms
	my @GO_hash; my @keys;
	
	my $query = $init_query . $WHERE;	# initialize the query
	foreach my $key(@keywords){         # for each keyword add the query parameter to the query
		$key = "%".$key."%";          # each keyword separated by spaces
		push @keys, ($key, $key, $key); # need it three times per keyword
		$query .= $query_param . "AND ";  # ready for another keyword
	}
	$query =~ s/[\n\t]+/ /g;  # get rid of all that crap
	$query =~ /(.*)(AND\s)$/;              # catch the last OR
	$query = $1;                          # and remove it
	$query .= $GROUP_BY;                 # add the final group-by statement
	
	my $sth = $self->dbh->prepare($query);  # now compile the query
	$sth->execute(@keys);                   # execute it
	
	my ($def, $acc, $term, $children);
	my %GO_hash;
	my @QueryResults = @{$sth->fetchall_arrayref};  # get result
	
	foreach my $row(@QueryResults){          # parse results
		($def, $acc, $term, $children) = @{$row};
		$GO_hash{$acc} = [$term, $def, $children];  # into the hash
	}
	$self->TopWindow->configure(-title => "Query: $keywords");   # configure the title
	$self->TopWindow->update;
 	$self->showKeys("Query: $keywords", \@QueryResults, \%GO_hash); # show result

}

sub showKeys {
	my ($self, $current_term, $QueryResult, $GO_hashref) = @_;    # hash is {acc}={term} where acc is eg. "8150", which is effectively "O:0008150" in the XML docs
	my %GO_hash;
	if (ref($GO_hashref) =~ "HASH"){
		 %GO_hash = %{$GO_hashref};    # get the hash of things to display
	} else {
		 %GO_hash = @{$GO_hashref};    # get the hash of things to display
    }

	$self->DefText->delete('1.0', 'end');  # clear the contents of the definition box
							
	my $Text = $self->GOText;       # get the text-box reference
	$Text->configure(-state => "normal");  # empty it and make it writable
	$Text->delete("1.0", "end");
	
	$Text->insert("end", "/                         \n", ["root"]);     # make the '/' root level symbol
   	$Text->tagConfigure("root", -foreground => "yellow");  				# TO GO TO ROOT
   	$Text->tagBind("root", "<Double-Button-1>",                         # bind the double-click
   			sub {undef $self->{query_stack};                             # delete everything from the stack
   				$self->showKeys("GO Ontology", $self->query_root);      # refresh the browser with the root contents
   				$self->TopWindow->configure(-title => "GO Ontology");   # configure the title
   				$self->TopWindow->update;
   			});
	
	unless ($#{$self->{query_stack}} < 0){                                   # IF THERE IS NO TREE TO MOVE UP THEN DONT DO THIS
		$Text->insert("end", "../                        \n", ["parent"]);	# TO MOVE UP THE TREE
		$Text->tagConfigure("parent", -foreground => "yellow");
      	$Text->tagBind("parent", "<Double-Button-1>",
      			sub {my ($grandparent_term, $QueryResult, $GO_hashref) = @{shift @{$self->{query_stack}}};   	# take off of the stack the verbose TERM of the grandparent, and the query parameters
      				
      				$self->showKeys($grandparent_term, $QueryResult, $GO_hashref);  # then call this routine with the parents query and variables
      				$self->TopWindow->configure(-title => $grandparent_term);
      				$self->TopWindow->update;
      				}
      			);
   	}
   	
	foreach my $acc(keys %GO_hash){					# ask for the sub-level keys--> there are always two:  term and definition
			
			my ($term, $def, $children) = @{$GO_hash{$acc}};  # take the term phrase of the sub-level
			$term .= "\n";
			$Text->insert('end', $term, [$acc]);           # print it,and tag it with its key GO:nnnnnn
			
			$def = "No Definition Available" if (!$def);
  			
			# bind the single-click to writing the definition into the DefText box
  			$Text->tagBind($acc, "<Button-1>",
  					sub {$self->DefText->delete('1.0', 'end');
  						$self->DefText->insert('end', $def);
  						$self->DefText->update;
  						}
  					);
			
			if ($children > 0){	                                 # if this term has children then it is not a leaf
				$Text->tagConfigure($acc, -foreground => "red"); # if it is not a leaf, then make it red
				$Text->tagBind($acc, "<Double-Button-1>",
						sub {unshift @{$self->{query_stack}}, [$current_term, $QueryResult, $GO_hashref];  # stack this term, the query, and the varibles for that query
							chomp $term;                                  # remove the newline character we added
							$self->showKeys($term, $self->do_query($self->tree_query, [$acc]));# then execute the standard tree query using this child's acc
						 	$self->TopWindow->configure(-title => $term);$self->TopWindow->update;
						 }
						);
			} else {
				$Text->tagConfigure($acc, -foreground => "green");  # if it is a leaf, then color it green
			}
			
						
			$Text->tagBind($acc, "<Button-2>",                      # bind the middle button
						sub {
							my $Annotation = GO_Annotation->new(id => $acc, term => $term, def => $def); # create a new, partially filled annotation object
							$self->Annotation($Annotation);  # encapsulate it so that it can be retrieved from outside.
							undef $Annotation;
						});
			
			
			if ($self->ObjectType eq "Scrolled"){     # use this if called as a Scrolled text widget
				my @framebindings = $Text->bindtags;
				unshift @framebindings, ('parent', 'root');
				$Text->bindtags(\@framebindings);
				my @bindings = $Text->Subwidget("text")->bindtags();
				shift @bindings;  # get rid of the Tk::Text binding itself to prevent highlighting of the sequence
				unshift @bindings, 'parent';
				unshift @bindings, 'root';
				$Text->Subwidget("text")->bindtags(\@bindings);
			} else {									# use this if called as a normal text widget
				#print "\nwrong widget type created - this is an ugly error!\n";
				$Text->bindtags(['all',
								'.',
								'parent',               # changed the order of binding
								'root', '.text',]); 	# because the text-box itself will respond to
			}                                           # double-clicks by highlighting the entire text!
			
			# put baloon-definitions here - not yet implemented
			#$Text->tagBind($key, "<Enter>")
	} # end of foreach my $acc
}

sub _set_queries {
	my ($self) = @_;
	$self->tree_query($self->dbh->prepare("select
											def.term_definition,
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
													
													
	$self->root_query($self->dbh->prepare("select
										def.term_definition,
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
												parent.term_type = ? and
												parent.id = relation.term1_id and
												child.id = relation.term2_id
												group by child.acc
											"));
												
}

1;

