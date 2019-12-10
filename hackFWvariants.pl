#!/usr/bin/perl
# perl ./hackFWvariants.pl

my $debug=1;

use 5.016;
use strict;
use warnings;
use utf8;

use open qw/:std :utf8/;
use XML::LibXML;

use Config::Tiny;
 # ; hackFWvariants.ini file looks like:
 # [hackFWvariants]
 # modeltag=Model Unspecified Complex Entry
 # modifytag=Complex_Form
 # infilename=Nktest.fwdata
 # outfilename=Nktest.new.fwdata
my $configfile = 'PromoteSubentries.ini';
my $inisection = 'hackFWvariants';
my $config = Config::Tiny->read($configfile, 'crlf');
#ToDo: should also use GetOpt::Long instead of setting variables as above
#ToDo: get the pathname of the INI file from $0 so that the two go together
die "Couldn't find the INI file\nQuitting" if !$config;
my $infilename = $config->{$inisection}->{infilename};
my $outfilename = $config->{$inisection}->{outfilename};

my $lockfile = $infilename . '.lock' ;
die "A lockfile exists: $lockfile\
Don't run $0 when FW is running.\
Run it on a copy of the project, not the original!\
I'm quitting" if -f $lockfile ;

my $modelmax= $config->{$inisection}->{numberofmodels};
die "numberofmodels not specified" if !defined $modelmax;
my $modeltag;
my $modifytag;
my $modelcount;
for ($modelcount =1; $modelcount <=$modelmax; $modelcount++) {
	my $thistag = 'modeltag' . $modelcount;
	$modeltag = $config->{$inisection}->{$thistag};
	$thistag = 'modifytag' . $modelcount;
	$modifytag = $config->{$inisection}->{$thistag};
	if ( (!defined $modeltag) || (!defined $modifytag)) {
		say STDERR "Skipping Model #$modelcount";
		next;
		}

	if ( (index($modeltag, $modifytag) != -1) or  (index($modifytag, $modeltag) != -1)) {
	# use index because Xpath doesn't use regex and we use Xpath to query the FW project
	# BUG: should check each modifytag against all the modeltags and other modifytags
		say STDERR "Use different tags for modeltag and modifytag. One contains the other in entry #$modelcount:";
		say STDERR "modeltag$modelcount=", $modeltag;
		say STDERR "tag$modelcount=", $modifytag;
		say STDERR "Ignoring entry #$modelcount";
		delete $config->{$inisection}->{"modeltag$modelcount"};
		delete $config->{$inisection}->{"modifytag$modelcount"};
		}
	}
say "Processing fwdata file: $infilename";

my $fwdatatree = XML::LibXML->load_xml(location => $infilename);

my %rthash;
foreach my $rt ($fwdatatree->findnodes(q#//rt#)) {
	my $guid = $rt->getAttribute('guid');
	$rthash{$guid} = $rt;
	}
for ($modelcount =1; $modelcount <=$modelmax; $modelcount++) {
	my $thistag = 'modeltag' . $modelcount;
	$modeltag = $config->{$inisection}->{$thistag};
	$thistag = 'modifytag' . $modelcount;
	$modifytag = $config->{$inisection}->{$thistag};
	next if ( (!defined $modeltag) || (!defined $modifytag));
	say "modeltag$modelcount=", $modeltag if $debug;
	say "modifytag$modelcount=", $modifytag if $debug;

	my ($modelTextrt) = $fwdatatree->findnodes(q#//*[contains(., '# . $modeltag . q#')]/ancestor::rt#);
	if (!$modelTextrt) {
		say "The model, '", $modeltag, "' isn't in any records";
		next;
		}
	# say  rtheader($modelTextrt) ;

	my ($modelOwnerrt) = traverseuptoclass($modelTextrt, 'LexEntry');
	say  'For the model entry, using:', displaylexentstring($modelOwnerrt);

	my $modelentryref = $rthash{$modelOwnerrt->findvalue('./EntryRefs/objsur/@guid')};
	my $modelEntryTypeName;
	if ($modelentryref) {
		# Fetch the name of the ComplexEntryType that the model uses
		my $modelEntryTypert = $rthash{$modelentryref->findvalue('./ComplexEntryTypes/objsur/@guid')};
		$modelEntryTypeName = $modelEntryTypert->findvalue('./Name/AUni'); 
		say "It has a $modelEntryTypeName EntryType";
		}
	else {
		die "The model entry doesn't refer to another entry\nQuitting";
	}
	my ($modelHideMinorEntryval) = $modelentryref->findvalue('./HideMinorEntry/@val');
	my ($modelRefTypeval) = $modelentryref->findvalue('./RefType/@val');
	my $modelComplexEntryTypesstring= ($modelentryref->findnodes('./ComplexEntryTypes'))[0]->toString;
	my ($modelHasAPrimaryLexemes) = $modelentryref->findnodes('./PrimaryLexemes') ;
	my ($modelHasAShowComplexFormsIn) = $modelentryref->findnodes('./ShowComplexFormsIn');
	say ''; say '';
=pod
	say 'Found the model stuff:';
	say 'HideMinorEntry val:', $modelHideMinorEntryval;
	say 'RefType val:', $modelRefTypeval;
	say 'ComplexEntryTypes (string):', $modelComplexEntryTypesstring;
	say 'Has a PrimaryLexemes' if $modelHasAPrimaryLexemes;
	say 'Has a ShowComplexFormsIn' if $modelHasAShowComplexFormsIn;
	say 'End of the model stuff:';
=cut

	foreach my $seToModifyTextrt ($fwdatatree->findnodes(q#//*[contains(., '# . $modifytag . q#')]/ancestor::rt#)) {
		my ($seModifyOwnerrt) = traverseuptoclass($seToModifyTextrt, 'LexEntry'); 
		say  "Modifying Reference to a $modelEntryTypeName for:", displaylexentstring($seModifyOwnerrt) ;	
		my $entryreftomodify = $rthash{$seModifyOwnerrt->findvalue('./EntryRefs/objsur/@guid')};
		# say 'EntryRefToModify Before: ', $entryreftomodify;
		if (!$entryreftomodify->findnodes('./ComponentLexemes')) {
			say STDERR "No Component Lexemes for: ", displaylexentstring($seModifyOwnerrt);
			next;
			}
		# Attribute values are done in place
		(my $attr) = $entryreftomodify->findnodes('./HideMinorEntry/@val');
		$attr->setValue($modelHideMinorEntryval) if $attr; 
		($attr) = $entryreftomodify->findnodes('./RefType/@val');
		$attr->setValue($modelRefTypeval) if $attr; 
		
		# New nodes are built from strings and inserted in order
		my $newnode = XML::LibXML->load_xml(string => $modelComplexEntryTypesstring)->findnodes('//*')->[0];
		# the above expression makes a new tree from the model ComplexEntryTypestring
		$entryreftomodify->insertBefore($newnode, ($entryreftomodify->findnodes('./ComponentLexemes'))[0]);
		
		# Additional new nodes use the objsur@guid from the ComponentLexemes
		# Stringify the ComponentLexemes node, change the tags, nodify the changed string and put the new node in its place
		my ($CLstring) = ($entryreftomodify->findnodes('./ComponentLexemes'))[0]->toString;
		my $tempstring = $CLstring;
		if ($modelHasAPrimaryLexemes)  {
			$tempstring =~ s/ComponentLexemes/PrimaryLexemes/g;
			$newnode = XML::LibXML->load_xml(string => $tempstring)->findnodes('//*')->[0];
			$entryreftomodify->insertBefore($newnode, ($entryreftomodify->findnodes('./RefType'))[0]);
			}
		$tempstring = $CLstring;
		if ($modelHasAShowComplexFormsIn)  {
			$tempstring =~ s/ComponentLexemes/ShowComplexFormsIn/g;
			$newnode = XML::LibXML->load_xml(string => $tempstring)->findnodes('//*')->[0];
			$entryreftomodify->insertAfter($newnode, ($entryreftomodify->findnodes('./RefType'))[0]);
			}
		# remove the VariantEntryTypes (VET) node if it's there
		my ($VETnode) = $entryreftomodify->findnodes('./VariantEntryTypes') ;
			$VETnode->parentNode->removeChild($VETnode) if $VETnode ;
=pod
		say "";
		say "EntryRefToModify  After: ", $entryreftomodify ;
		say "";
		say "";
=cut
	}

}

my $xmlstring = $fwdatatree->toString;
# Some miscellaneous Tidying differences
$xmlstring =~ s#><#>\n<#g;
$xmlstring =~ s#(<Run.*?)/\>#$1\>\</Run\>#g;
$xmlstring =~ s#/># />#g;
say "Finished processing, writing modified  $outfilename" ;
open my $out_fh, '>:raw', $outfilename;
print {$out_fh} $xmlstring;


# Subroutines
sub rtheader { # dump the <rt> part of the record
my ($node) = @_;
return  ( split /\n/, $node )[0];
}

sub traverseuptoclass { 
	# starting at $rt
	#    go up the ownerguid links until you reach an
	#         rt @class == $rtclass
	#    or 
	#         no more ownerguid links
	# return the rt you found.
my ($rt, $rtclass) = @_;
	while ($rt->getAttribute('class') ne $rtclass) {
#		say ' At ', rtheader($rt);
		if ( !$rt->hasAttribute('ownerguid') ) {last} ;
		# find node whose @guid = $rt's @ownerguid
		$rt = $rthash{$rt->getAttribute('ownerguid')};
	}
#	say 'Found ', rtheader($rt);
	return $rt;
}

sub displaylexentstring {
my ($lexentrt) = @_;

my ($formguid) = $lexentrt->findvalue('./LexemeForm/objsur/@guid');
my $formrt =  $rthash{$formguid};
my ($formstring) =($rthash{$formguid}->findnodes('./Form/AUni/text()'))[0]->toString;
# If there's more than one encoding, you only get the first

my ($homographno) = $lexentrt->findvalue('./HomographNumber/@val');

my $guid = $lexentrt->getAttribute('guid');
return qq#$formstring hm:$homographno (guid="$guid")#;
}
