=head1 NAME

Bio::Tk::GO_Browser.pm - Browser of the GO ontology

=head1 SYNOPSIS

 use Tk;
 use Bio::Tk::GO_Browser_tree;  # in bioperl-gui from BioPerl
 require GO::AppHandle;  # you must have the GO perl_api from BDGP
                         # contact Chris Mungall for details
                         # (cjm@fruitfly.bdgp.berkeley.edu)
 
 &begin;
 MainLoop;
 
 sub begin {
   my $mw = MainWindow->new; 
   my $frame = $mw->Frame->pack;
   my $GO = GO_Browser_tree->new($frame);
 
   my $Annotation;
   $GO->browser->bind("<Double-Button-1>" => sub {
     $Annotation = $GO->annotation; # see Bio::Tk::GO_Annotation
     my $acc = $GO->acc;          # retrieve acc of term
     my $term_name = $GO->name;   # retrieve name of term
     my $def = $GO->definition;   # retrieve definition for term
     my $TERM = $GO->term;        # or retrieve the GO::Model::Term object
     print "Acc# $acc\n";
     print "Term $term_name\n";
     print "Definition $def\n";
     print "Public Acc " . $TERM->public_acc . "\n";
    });
 } 


=head1 DESCRIPTION and ACKNOWLEDGEMENTS

Fills a Tk::Frame widget with a browsable display of the GO ontology (http://www.geneontology.org/).
Items in red are "branches", while items in green are "leaves" of the GO ontology tree.  Numbers
after the term name indicate the number of gene products annotated below that node.
 * Single-Clicking on a term displays the definition of a term.
 * Clicking the +/- boxes open and close sub-branches of the tree.
 * Double-clicking on any element records the clicked-upon term and
 definition (if available) and this event can be trapped by the
 top-level windowing system to retrieve this info for whatever
 external application you are building.

This module uses "the awesome power" of the go_perl API.  Many thanks to Chris Mungall for taking
the time to write a comprehensive and beautifully functional API to the GO ontology database.
Contact for go_perl API: Chris Mungall (cjm@fruitfly.bdgp.berkeley.edu).  See also "DEPENDANCIES"
below.

This is just the beginning!  Using "the awesome power" of the go_perl API I plan to
greatly enhance the functionality of this browser over the next couple of months.  Please
send me any requests for additional 'toys' you would like to have in this module.


=head1 AUTHORS

Mark Wilkinson (mwilkinson@gene.pbi.nrc.ca)
Plant Biotechnology Institute, National Research Council of Canada.

 Version 1: Copyright (c) National Research Council of Canada, October, 2000.
 Version 2: Copyright (c) National Research Council of Canada, March, 2001.
 Version 3: Copyright (c) National Research Council of Canada, September, 2001.

=head1 DISCLAIMER

Anyone who intends to use and uses this software and code acknowledges and
agrees to the following: The National Research Council of Canada (herein "NRC")
disclaims any warranties, expressed, implied, or statutory, of any kind or
nature with respect to the software, including without limitation any warranty
or merchantability or fitness for a particular purpose.  NRC shall not be liable
in any event for any damages, whether direct or indirect,
consequential or incidental, arising from the use of the software.

=cut

=head1 NOTE TO AnnotationWorkbench and Genquire USERS

This version of GO_Browser is sufficiently different from the previous versions
that it was not realistic to attempt to make it backwards compatible, thus it will
not work with any version of AnnotationWorkbench or Genquire prior to GenquireII.
If you require an earlier version of GO_Browser, please contact Mark Wilkinson
(mwilkinson@gene.pbi.nrc.ca) and I will send you the appropriate version for your
release of the annotation software.

=cut

=head1 DEPENDANCIES

GO_Browser uses Chris Mungall's API modules.  These can be downloaded from BDGP.
Browse to http://www.fruitfly.org/annot/go/database/ and follow the links to
"GO Database Toolkits" for the location of these files, and instructions for
obtaining them via CVS.

MS Windows users:  it is possible to set up CVS on MS Windows!  It just takes 
a bit of effort! 

=cut

=head1 QUERIES

At the moment you can query single or comma-delimited multiple words (AND).
Matching terms are highlighted in the tree.  It appears that queries are
done against the term name, definition, and synonym(?)

=cut


=head1 APPENDIX

The remaining documentation details deal with the object methods.
Since most of the methods deal with extracting data from a GO::Model::Term
object, these methods are called using the same function names to keep things clear.

=cut

=head2 new

 Title     :	new
 Usage     :	my $GO = GO_Browser_tree->new($frame, %args)
 Function  :	return a GO browser object
 Returns   :	Bio::Tk::GO_Browser object
 Args      :	
      $Frame,     		# an existing Tk Frame widget (required)
      TopWindow   => $top,	# optional - MainWindow object
      dbname      => $db, 	# optional - database name (default "go")
      host        => $host,	# optional - default determined at run time
      leaf_color  => $color	# optional - default "darkgreen"
      branch_color=> $color	# optional - default "red"
      background  => $color	# optional - default "white"
      textbg      => $color	# optional - default "blue"
      textfg      => $color	# optional - default "white"
      height      => $high	# optional - default 30
      width       => $wide	# optional - default 70
      GO_API      => $apph	# optional - existing API AppHandle
      count       => $count	# optional - "shallow", "deep"; counts # mapped gene products


=cut


=head2 acc

 Title     : acc
 Usage     : my $acc = $GO->acc
 Function  : return the GO accession number of the selected term
 Returns   : Integer
 Args      :


=cut


=head2 name

 Title     : name
 Usage     : my $name = $GO->name
 Function  : return the GO term name of the selected term
 Returns   : scalar
 Args      :


=cut


=head2 definition

 Title     : definition
 Usage     : my $def = $GO->definition
 Function  : return the definition (if available) of the selected term
 Returns   : Integer
 Args      :


=cut


=head2 public_acc

 Title     : public_acc
 Usage     : my $pubacc = $GO->public_acc
 Function  : return the full GO accession number (eg GO:00003876)
 Returns   : scalar
 Args      :


=cut


=head2 term

 Title     : term
 Usage     : my $TERM = $GO->term
 Function  : return the GO::Model::Term object of the selected term
 Returns   : GO::Model::Term object
 Args      :


=cut

=head2 annotation

 Title     : annotation
 Usage     : my $ANNOT = $GO->annotation
 Function  : return a Bio::Tk::GO_Annotation object of the selected term
 Returns   : Bio::Tk::GO_Annotation object
 Args      :


=cut

package GO_Browser_tree;

use strict;
use Carp;
use vars qw($AUTOLOAD);
use Tk;
use Tk::Label;
use Tk::Tree;
use Tk::ItemStyle;
use GO::AppHandle;
use LWP::UserAgent;
use Bio::Tk::GO_Annotation;

require Exporter;
use vars qw(@ISA @EXPORT); #keep 'use strict' happy
@ISA = qw(Exporter); 
@EXPORT = qw(new);


{
	#Encapsulated class data
	
	#___________________________________________________________
	#ATTRIBUTES
    my %_attr_data = #     				DEFAULT    	ACCESSIBILITY
                  (	TopWindow		=>	[undef, 	'read/write'],
					dbname 			=>	["go", 		'read/write'],
					host 			=>	[undef, 'read/write'],
					leaf_color		=>	["darkgreen", 	'read/write'],
					branch_color	=>	["red",		'read/write'],
					background		=>	["white", 	'read/write'],
					textbg			=>	["darkblue",'read/write'],
					textfg			=>	["white",	'read/write'],
					height			=>	["30", 		'read/write'],
					width			=>	["70", 		'read/write'],
					frame			=>	[undef, 	'read/write'],
					browser			=>	[undef, 	'read/write'],
					def_text		=>	[undef, 	'read/write'],
					query_text		=>	[undef, 	'read/write'],
					GO_API			=>	[undef, 	'read/write'],
					path			=>	[undef, 	'read/write'],
					name			=>	[undef,		'read/write'],
					term	 		=>	[undef, 	'read/write'],
					acc				=>	[undef, 	'read/write'],
					definition		=>	[undef, 	'read/write'],					
					public_acc		=>	[undef, 	'read/write'],
					Annotation		=>	[undef, 	'read/write'],
					count			=>	[undef, 	'read/write'], # count, deep, undef
					
                    );

   #_____________________________________________________________

    # METHODS, to operate on encapsulated class data

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

sub DESTROY {
	my $self = shift;
	undef $self;
}

sub new {
	my ($caller, $frame, %args) = @_;

	unless ($frame->isa('Tk::Frame')){print "must be initialised with an exising Tk::Frame object as the first argument\n"; return 0};
	
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

	$self->frame($frame);
	$self->frame->Busy;$self->frame->update;

	# we might need to determine the host 'on the fly'
	# this can be done by a call to the server.cfg, which
	# returns the database type and hostname (eg:  mysql sin.lbl.gov)
	unless ($self->host){	
		my $ua = new LWP::UserAgent;
		my $req = new HTTP::Request GET => 'http://www.fruitfly.org/annot/go/database/server.cfg';
        $req->content('match=www&errors=0');
		my $res = $ua->request($req);

        if ($res->is_success) {
            my $resp =  $res->content;
			my $host = ($resp =~ /\w+\s+(.*)/ && $1);
			$self->host($host);
		}
		unless ($self->host){
			warn "unable to determine host name from BDGP website\n";
			return 0;
		}       
	}
	
	unless ($self->GO_API){$self->GO_API(GO::AppHandle->connect(-dbname => $self->dbname, -dbhost => $self->host))};
	unless ($self->GO_API){
		warn "unable to connect to the GO database at " . ($self->host) . "\n";
		return 0;
	}
	
	my $fullroots = $self->GO_API->get_root_term;
	
	$self->def_text($self->frame->Scrolled("Text",
								-height => 4,
								-scrollbars => "sw",
								-wrap => "word",
								-background => $self->textbg,
								-foreground => $self->textfg));


	# set up the three Query frame elements - a label, a text box, and a button
	my $query_frame = $frame->Frame();
	my $label = $query_frame->Label(-text => "Query:", -background => "white", -foreground => "black");
	$label->pack(-side => 'left', -expand => 0);
	my $query_button = $query_frame->Button(-text => "execute", -command => sub {$self->do_query});
	
	$query_button->pack(-side => 'right', -expand => 0);
	
	$self->query_text($query_frame->Text(
								-height => 1,
								-background => $self->textbg,
								-foreground => $self->textfg));
	$self->query_text->pack(-side => 'left', -expand => 1, -fill => 'x');
	# end of query frame things.

	
	$self->frame->ItemStyle('text', -stylename => 'branch', -foreground => $self->leaf_color, -background => $self->background);
	$self->frame->ItemStyle('text', -stylename => 'leaf', -foreground => $self->branch_color, -background => $self->background);

	$self->browser($self->frame->Scrolled('Tree', 
					-itemtype   => 'text',
					-separator  => '|',
					-selectmode => 'multiple',
					-indicator => 1,
					-height => $self->height,
					-width => $self->width,
					-background => $self->background,
					-browsecmd => sub {my $path = shift; $self->frame->Busy; $self->frame->update; $self->browsed($path);$self->frame->Unbusy}, 
					-opencmd  => sub {my $path = shift; $self->frame->Busy; $self->frame->update; $self->clickedOpen($path);$self->frame->Unbusy},			
					-command => sub {my $path = shift; $self->frame->Busy; $self->frame->update; $self->selectEntry($path);$self->frame->Unbusy},
					));
	
	foreach (($fullroots)) {
		my $label = $_->name;
		$self->browser->add($_->name, -text=>$label );
		$self->browser->setmode($_->name, "close");
	}

	my $graph = $self->GO_API->get_graph_by_terms(-terms=>[$fullroots], -depth=>1, -template => {acc=>1, name=>1});

	$self->addTreeNode($graph);

	$self->def_text->pack(-side => 'bottom', -fill => 'x');
	$query_frame->pack(-side => 'top', -expand => 0, -fill => 'x');
	$self->browser->pack(-side => 'top', -expand => 1, -fill => "both");

	$self->frame->Unbusy;
    return $self;

}

sub addTreeNode {
	my ($self, $graph, $select) = @_;
	
	my $leaf_terms = $graph->get_leaf_nodes;
	foreach my $term(@{$leaf_terms}){
		my $children = $graph->n_children($term->acc);
		my $paths = $graph->paths_to_top($term->acc);
		foreach my $path(@{$paths}){
			$self->_addPathToTree($path, $term, $children, $select);
		}
	}
}	

sub browsed {
	my ($self, $path) = @_;
	return unless $path;  						# pipe-delimited string of term names
	$self->_fill_in_details($path);				# extract all info about this term and store it in $self to allow viewing from outside of this module
}

sub clickedOpen {
	my ($self, $path) = @_;
	if ($self->browser->info('children', $path)){
		foreach $path($self->browser->info('children', $path)){
			$self->browser->show("entry", $path);
		}
		#return;
	}	
	#print "$path\n";
	my $name = ($path =~ /.*\|(.*)$/ && $1);
	my $term = $self->GO_API->get_term({name => $name}, "shallow");
	my $graph = $self->GO_API->get_graph_by_terms(-terms=>[$term], -depth => 1, -template => {acc=>1, -name => 1});
	$self->addTreeNode($graph);
}


sub _addPathToTree {
	# takes a $path object and converts it to a string that is
	# readable by the Tree widget (text delimited by |)
	my ($self, $path, $term, $children, $select) = @_;
	my @revpath = reverse @{$path->term_list};
	my $browser = $self->browser;
	my $termstring;
	
	foreach my $node(@revpath){
		$termstring .= $node->name;
		if ($browser->info("exists", $termstring)){
			$browser->setmode($termstring, "close");
			$browser->show("entry", $termstring);
		}
		else {
			my $extra;
			if ($self->count eq "deep"){$extra =  "(".($self->GO_API->get_deep_product_count({term=>$node})).")"}
			elsif ($self->count eq "shallow"){$extra = "(".($self->GO_API->get_product_count({term=>$node})).")"}		
			$browser->add($termstring, -text=>($node->name . $extra));
			$browser->entryconfigure($termstring, -style=>'branch');
			$browser->setmode($termstring, "close");
			$browser->show("entry", $termstring);
		};
		$termstring .= "|";
	}
	$termstring .=  $term->name;	
	unless ($browser->info("exists", $termstring)){
		my $extra;
		if ($self->count eq "deep"){$extra =  "(".($term->n_deep_products).")"}
		elsif ($self->count eq "shallow"){$extra = "(".($term->n_products).")"}		
		$browser->add($termstring, -text => (($term->name) . $extra));
		my $openclose = ($children)?"open":"close";
		$browser->setmode($termstring, $openclose);
		if ($children){
			$browser->entryconfigure($termstring, -style=>'branch')
		} else {
			$browser->entryconfigure($termstring, -style=>'leaf');
			$browser->setmode($termstring, "none");
		};
	}
	$browser->show("entry", $termstring);
	if ($select){$browser->selectionSet($termstring)}
}

sub selectEntry {
	my ($self, $path) = @_;
	$self->_fill_in_details($path);
}

sub _fill_in_details {
	my ($self, $path) = @_;
	return unless $path;  						# pipe-delimited string of term names

	my $term = ($path =~ /.*\|(.*)$/ && $1);  	# get the last one
	unless ($term){$path =~ /(Gene\_Ontology)/} # the above might fail, so check that we are not at root
	return unless $term;						# the term text string may fail to be found... I hope not!
	my $TERM = $self->GO_API->get_term({name => $term}, {acc=>1, definition=>1}); # get the term OBJECT
	return unless $TERM;						# this would be a problem with the Go database
	$self->def_text->delete('1.0'	, 'end');  	# erase current contents and write the definition into the text box
	$self->def_text->insert('end', ($TERM->definition));
	$self->name($term);
	$self->term($TERM);
	$self->path($path);
	$self->definition($TERM->definition);
	$self->acc($TERM->acc);
	$self->public_acc($TERM->public_acc);
	if ($self->TopWindow){$self->TopWindow->configure(-title => $TERM->public_acc . " " . $self->name);}
}

sub annotation {
	my ($self) = @_;
	my $Annotation = GO_Annotation->new(id => $self->acc, term => $self->name, def => $self->definition); # create a new, partially filled annotation object
	return $Annotation;
}

sub do_query {
	my ($self) = @_;
	my $query = $self->query_text->get('1.0', "end");
	my @param = split ",",$query;
	$self->frame->Busy;
	foreach my $param(@param){
		$param = ($param =~ /\s*(.*)\s*/ && $1);
		my $graph = $self->GO_API->get_graph_by_search("*$param*", 1, {acc=>1, name=>1});
		$self->addTreeNode($graph, "select");
	}
	$self->frame->Unbusy;
}	
	
			
1;