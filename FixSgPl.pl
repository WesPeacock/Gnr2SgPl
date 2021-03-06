#!/usr/bin/perl
# You should probably use the related bash script to call this script, but you can use:
my $USAGE = "Usage: $0 [--configfile Gnr2SgPl.ini] [--section Gnr2SgPl] [--debug] [--checkini] [--gnrdmp] [--sgpldmp]";
# debug -- dump debugging information
# checkini -- quit after processing configfile

use 5.016;
use strict;
use warnings;
use English;
use Data::Dumper qw(Dumper);
use utf8;
use Data::GUID;
use open qw/:std :utf8/;
use XML::LibXML;

use Getopt::Long;
GetOptions (
	'configfile:s'   => \(my $configfile = "Gnr2SgPl.ini"), # ini filename
	'section:s'   => \(my $inisection = "Gnr2SgPl"), # section of ini file to use
	'debug'       => \(my $debug = 0),
	'gnrdmp'       => \(my $gnrdmp = 0),
	'sgpldmp'       => \(my $sgpldmp = 0),
	'checkini'       => \(my $checkini = 0),
	) or die $USAGE;

use Config::Tiny;
 # ; Gnr2SgPl.ini file looks like:
 # [Gnr2SgPl]
 # FwdataIn=FwProject-before.fwdata
 # #FwdataOut is used by FixSgPl.pl
 # FwdataOut=FwProject.fwdata
 # SgPlFieldName=Valency
 # PluralRelationName=Plural
 # SingularRelationName=Singular
 # LiftFile=lift.lift
 # LogFile=Gnr2SgPl.log

my $config = Config::Tiny->read($configfile, 'crlf');

die "Couldn't find the INI file:$configfile\nQuitting" if !$config;
my $infilename = $config->{$inisection}->{FwdataIn};
my $outfilename = $config->{$inisection}->{FwdataOut};
my $logfilename = $config->{$inisection}->{LogFile};
my $sgplfieldname = $config->{$inisection}->{SgPlFieldName};
my $plrelname = $config->{$inisection}->{PluralRelationName};
my $sgrelname = $config->{$inisection}->{SingularRelationName};
my $genrelname = $config->{$inisection}->{GeneralRelationName};

my $lockfile = $infilename . '.lock' ;
die "A lockfile exists: $lockfile\
Don't run $0 when FW is running.\
Run it on a copy of the project, not the original!\
I'm quitting" if -f $lockfile ;

say STDERR "Loading log file: $logfilename";
my $logtree = XML::LibXML->load_xml(location => $logfilename);

=pod
# Log file looks like:
# <?xml version="1.0" encoding="UTF-8" ?>
# <pairs>
# <pair guid="00fe7802-9317-4bf1-86a2-4bc7e300a85a" entry1id=
# 		"SG_k??b_263aa645-97e9-45ac-9a1d-37daabfe64ef" entry1gloss=
# 		"special matte; handle for men's /daate/ calabash" entry2id=
#
# 		"PL_kobano_092c3252-68ed-471c-b394-90fa4f02e6dc" entry2gloss=
# 		"special mattes"/>

# Note that
#      All the fields are empty, all the pertinent data is in the attributes
#      guid of the Gnr cross reference
#      entry{1,2}id attribute is separated by underscores:
#          <valency>_lexeme_lexref-guid
#      entry{1,2}gloss is English gloss
=cut

die "config:". Dumper($config) if $checkini;

say STDERR "Loading fwdata file: $infilename";
my $fwdatatree = XML::LibXML->load_xml(location => $infilename);

my %rthash;
foreach my $rt ($fwdatatree->findnodes(q#//rt#)) {
	my $guid = $rt->getAttribute('guid');
	$rthash{$guid} = $rt;
	}

# Bug: doesn't handle cases where LexRefType Names don't occur as complete <AUni> fields
my ($genrelrt) = $fwdatatree->findnodes(q#//AUni[text()='# . $genrelname . q#']/ancestor::rt[@class='LexRefType']#);
my $sgn = $genrelrt->serialize();
say STDERR $sgn  if $gnrdmp;

my ($sgrelrt) = $fwdatatree->findnodes(q#//AUni[text()='# . $sgrelname . q#']/ancestor::rt[@class='LexRefType']#);
my $sgabbrev = uc( ($sgrelrt->findnodes('./Abbreviation/AUni/text()'))[0]->serialize() );
say STDERR "Singular Abbrev: $sgabbrev"  if $sgpldmp;
my $ssg = $sgrelrt->serialize();
say STDERR "Singular LexReftype:"  if $sgpldmp;
say STDERR $ssg  if $sgpldmp;

my ($plrelrt) = $fwdatatree->findnodes(q#//AUni[text()='# . $plrelname . q#']/ancestor::rt[@class='LexRefType']#);
my $plabbrev = uc( ($plrelrt->findnodes('./Abbreviation/AUni/text()'))[0]->serialize() );
say STDERR "Plural Abbrev: $plabbrev"  if $sgpldmp;
my $spl = $plrelrt->serialize();
say STDERR "Plural LexReftype:"  if $sgpldmp;
say STDERR $spl  if $sgpldmp;

my $paircnt=0;
my $pairtotal=0;
foreach my $pair ($logtree->findnodes(q#//pair#)) {
	$pairtotal++;
	my $pairguid = $pair->getAttribute('guid');
	say STDERR $pairguid;
	my ($valen1, $lex1, $guid1) = split('_', $pair->getAttribute('entry1id'));
	my ($valen2, $lex2, $guid2) = split('_', $pair->getAttribute('entry2id'));
	my $sg_guid = $guid1;
	my $pl_guid = $guid2;
	if ($valen1 eq $plabbrev) {
		$pl_guid = $guid1;
		$sg_guid = $guid2;
		}

	my ($sgrefpointer) = $genrelrt->findnodes(q#./Members/objsur[@guid="# . $pairguid . q#"]#);
	# Find the SG reftype members and move the old gnr pointer into it.
	my ($members) = $sgrelrt->findnodes(q#./Members#);
	if (! $members) {
		$members = XML::LibXML::Element->new("Members");
		my ($maptype) = $sgrelrt->findnodes(q#./MappingType#);
		$sgrelrt->insertAfter($members, $maptype);
	}
	$members->addChild($sgrefpointer);

# Clone the pointer and assign a new guid to it and put it into the PL reftype members
	my $plrefpointer = $sgrefpointer->cloneNode(1);
	my $newrefguid = lc Data::GUID->new->as_string;
	$plrefpointer->setAttribute('guid', $newrefguid);
	($members) = $plrelrt->findnodes(q#./Members#);
	if (! $members) {
		$members = XML::LibXML::Element->new("Members");
		my ($maptype) = $plrelrt->findnodes(q#./MappingType#);
		$plrelrt->insertAfter($members, $maptype);
	}
	$members->addChild($plrefpointer);

	my $sgnode = $rthash{$pairguid};
	$sgnode->setAttribute('ownerguid', $sgrelrt->getAttribute('guid'));
	my @objsurnodes = $sgnode->findnodes('./Targets/objsur');
	$objsurnodes[0]->setAttribute('guid', $pl_guid);
	$objsurnodes[1]->setAttribute('guid', $sg_guid);

	# Clone the sgnode and put the clone right after the sgnode assign its new guid and ownerguid, ie PL
	my $plnode = $sgnode->cloneNode(1);
	$sgnode->parentNode->insertAfter($plnode,$sgnode);
	$plnode->setAttribute('guid', $newrefguid);
	$rthash{$newrefguid} = $plnode;
	$plnode->setAttribute('ownerguid', $plrelrt->getAttribute('guid'));
	@objsurnodes = $plnode->findnodes('./Targets/objsur');
	$objsurnodes[0]->setAttribute('guid', $sg_guid);
	$objsurnodes[1]->setAttribute('guid', $pl_guid);


	$paircnt++;
	last if ($paircnt > 5) && $debug;
	}

say STDERR "Found $paircnt of $pairtotal pairs";
my $xmlstring = $fwdatatree->toString;
# Some miscellaneous Tidying differences
$xmlstring =~ s#><#>\n<#g;
$xmlstring =~ s#(<Run.*?)/\>#$1\>\</Run\>#g;
$xmlstring =~ s#/># />#g;
say "";
say "Finished processing, writing modified  $outfilename" ;
open my $out_fh, '>:raw', $outfilename;
print {$out_fh} $xmlstring;

# Subroutines
sub rtheader { # dump the <rt> part of the record
my ($node) = @_;
return  ( split /\n/, $node )[0];
}
