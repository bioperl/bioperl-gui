package ExternalViewerLinker;


my %dbIDs=( 'GI' => { name =>'GenPept', url => "http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Retrieve&db=Protein&dopt=GenPept&list_uids="},
	    'PID' => { 'g' => { name => 'GenPept', url=> 'http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?cmd=Retrieve&db=Protein&dopt=GenPept&list_uids='}
		   },
	    'taxon' => { name => 'Taxonomy', url => "http://www.ncbi.nlm.nih.gov/htbin-post/Taxonomy/wgetorg?mode=Info&id="}
	    );

$ExternalViewerLinker::browser_command="netscape -remote 'openURL(_URL_)' || netscape \"_URL_\" ";

sub new {
    my $class=shift;
    my $self={};

    bless $self,$class;

    return $self;
    
}

sub reactive_zone_selected {
    my $self=shift;
    my $feature=shift;

    my $menu=new Gtk::Menu;
    my $menuitem;
    my $items=0;
    if ($feature->has_tag('db_xref')) {
	foreach my $xref ($feature->each_tag_value('db_xref')) {
	    my ($db,$id)=split(':',$xref);
	    if (defined $dbIDs{$db}) {
		my $url=$dbIDs{$db}->{url}."$id";
		my $urlname=$dbIDs{$db}->{name};
		if ($db eq 'PID') {
		    if ($id =~ /(\w)(\d+)/) {
			my ($subdb,$subid) = ($1,$2);
			$url= $dbIDs{'PID'}->{$subdb}->{url}."$subid";
			$urlname= $dbIDs{'PID'}->{$subdb}->{name};

		    }
		}
		$menuitem=new Gtk::MenuItem("$urlname");
		$menuitem->signal_connect('activate',sub { $self->view_link($url)});
		$menuitem->show();
		
		$menu->append($menuitem);
		$items++;
	    }
	}
    }

    if ($items == 0) {
	$menuitem=new Gtk::MenuItem ("No External Links Available");
	$menuitem->set_sensitive(0);
	$menu->append($menuitem);
	$menuitem->show();
    }

    $menu->popup(0,0,1,0);
}

sub view_link {
    my $self=shift;
    my $url=shift;
    
    my $command=$ExternalViewerLinker::browser_command;

    $command=~ s/_URL_/$url/g;

    system("$command &");
}

1
