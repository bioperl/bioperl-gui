#! /usr/bin/perl -w
eval {
    use Tk;
    use Bio::SeqIO;
    use lib '..';
    use Bio::Tk::SeqCanvas;

    use strict;
    my $testholder=0;

    print "1..6\n";
    Begin();
    MainLoop;
    #______________________________________________________________________________

    sub Begin {
	my $MapObj;
	my @Widgets;
	my $top = MainWindow->new;
	$top->title("Bio::Tk::SeqCanvas Test");
	my $SeqObj;

	#------------------------  BioPerl -----------------------------
	my $dir=`pwd`; my $fn;
	if ($dir =~ /\/t$/) {
	    $fn='testseq.gb';
	} else {
	    $fn='t/testseq.gb';
	}
	my $SIO = Bio::SeqIO->new(-file=> $fn, '-format' => 'GenBank');
	if ($SIO->isa("Bio::SeqIO")) {
	    print "ok 1\n"
	} else {
	    print "not ok 1\n";
	}
	$SeqObj = $SIO->next_seq();
	#---------------------------------------------------------------
	if ($SeqObj->isa("Bio::SeqI")) {
	    print "ok 2\n";
	    my $frame = $top->Frame('-background' => '#ffffff')->pack(-side => 'top', -fill => 'both');
	    my ($axis_length) = 900;

	    $MapObj = Bio::Tk::SeqCanvas->new($axis_length, $frame, undef, $SeqObj, -orientation => 'vertical'); # $MapObj is a handle to the map objects that you have just created
	} else {
	    print "not ok 2\n";
	}

	if ($MapObj->isa("Bio::Tk::SeqCanvas")) {
	    print "ok 3\n";
	} else {
	    print "not ok 3\n";
	}

	# FUNCTIONS ON $MapObj:
	#
	# $MapIDs = $MapObj->mapFeatures('draft'|'finished',\@SeqFeatureObjects)  :  maps the feature(s) onto the draft (white) or finished (blue) map,
	#										 returns a reference to a list of the MapID's of the mapped features
	#			      							 Features MUST have a *valid* $feature->source_tag for the existing map
	#
	# $MapObj->unmapFeatures($FeatureIDs)   :  $FeatureID is a reference to a list (eg. coming from $obj->getSelectedID)
	#               or
	# $MapObj->unmapFeatures(\@FeatureIDs)   :  reference to a real list
	#
	# $FeatureHashRef = $MapObj->getSelected()  :  returns a reference to a hash of selected FeatureID = $BioSeqFeatureObject
	#
	# $FeatureListRef = $MapObj->getSelectedID()  :  returns a reference to a list of selected FeatureID's
	#
	# $MapObj->clearSelection()  :  wipes the workspace of any selections (not the objects, just the 'selected' status)
	#
	# examples below:
	#

	$top->bind ("<Button-1>" => sub {my $FeaturesHashRef = $MapObj->getSelectedFeatures();
					 my %FeatureHash = %{$FeaturesHashRef};
					 foreach my $key (keys %FeatureHash) {
					     my @tags = $FeatureHash{$key}->all_tags();
					     #print "$key\n";
					     foreach my $tag (@tags) {
						 #print "     $tag = " . $FeatureHash{$key}{$tag} . "\n";
					     }
					     #print "\n";
					 }
					 $testholder = 1;
				     });
	$top->update;
	$top->eventGenerate("<Button-1>");
	if ($testholder == 1) {
	    print "ok 4\n";
	} else {
	    print "not ok 4\n";
	}

	$top->bind ("<Button-3>" => sub {my $FeaturesListRef = $MapObj->getSelectedIDs();
					 $MapObj->unmapFeatures($FeaturesListRef);
					 $testholder = 2;
				     });
	$top->update;
	$top->eventGenerate("<Button-3>");
	if ($testholder == 2) {
	    print "ok 5\n";
	} else {
	    print "not ok 5\n";
	}

	$top->bind ("<Button-2>" => sub {my $FeaturesHashRef = $MapObj->getSelectedFeatures();
					 my %FeatureHash = %{$FeaturesHashRef};
					 foreach my $key (keys %FeatureHash) {
					     $MapObj->unmapFeatures([$key]);
					     $MapObj->mapFeatures('finished', [$FeatureHash{$key}]);
					 }
					 $testholder = 3;
				     });
	$top->update;
	$top->eventGenerate("<Button-2>");
	if ($testholder == 3) {
	    print "ok 6\n";
	} else {
	    print "not ok 6\n";
	}
	$SeqObj->destroy;
	undef $SeqObj;
	undef $MapObj;
	$SIO->destroy;
	undef $SIO;
	$top->destroy;

    }
}
