#!/usr/bin/perl
# You should probably use the related bash script to call this script, but you can use: 
my $USAGE = "Usage: $0 [--configfile Gnr2SgPl.ini] [--section Gnr2SgPl] [--debug] [--checkini] [--gnrdmp] [--sgpldmp]";
# debug -- dump debugging information
# checkini -- quit after proscessing configfile
# gnrdmp -- dump master General Relation
# sgpldmp -- dump master Singular/Plural Relation

use 5.016;
use strict;
use warnings;
use English;
use Data::Dumper qw(Dumper);
use utf8;

use open qw/:std :utf8/;
use XML::LibXML;

use File::Basename;
my $scriptname = fileparse($0, qr/\.[^.]*/); # script name without the .pl

use Getopt::Long;
GetOptions (
	'configfile:s'   => \(my $configfile = "$scriptname.ini"), # ini filename
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
 # FwdataOut=FwProject.fwdata
 # SgPlFieldname=Valency
 # PluralRelationName=Plural
 # SingularRelationName=Singular
 # LiftFile=lift.lift
 # LogFile=Gnr2SgPl.log

my $config = Config::Tiny->read($configfile, 'crlf');

die "Couldn't find the INI file:$configfile\nQuitting" if !$config;
my $infilename = $config->{$inisection}->{FwdataIn};
my $outfilename = $config->{$inisection}->{FwdataOut};
my $liftfilename = $config->{$inisection}->{LiftFile};
my $logfilename = $config->{$inisection}->{LogFile};
my $sgplfieldname = $config->{$inisection}->{SgPlFieldname};
my $plrelname = $config->{$inisection}->{PluralRelationName};
my $sgrelname = $config->{$inisection}->{SingularRelationName};
my $genrelname = $config->{$inisection}->{GeneralRelationName};

my $lockfile = $infilename . '.lock' ;
die "A lockfile exists: $lockfile\
Don't run $0 when FW is running.\
Run it on a copy of the project, not the original!\
I'm quitting" if -f $lockfile ;


open(LOGFILE, '>:encoding(UTF-8)', "$logfilename");

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
my $ssg = $sgrelrt->serialize();
say LOGFILE "Singular LexReftype:"  if $sgpldmp;
say LOGFILE $ssg  if $sgpldmp;

my ($plrelrt) = $fwdatatree->findnodes(q#//AUni[text()='# . $plrelname . q#']/ancestor::rt[@class='LexRefType']#);
my $spl = $plrelrt->serialize();
say LOGFILE "Plural LexReftype:"  if $sgpldmp;
say LOGFILE $spl  if $sgpldmp;

say STDERR "Loading LIFT file: $liftfilename";
my $lifttree = XML::LibXML->load_xml(location => $liftfilename);

my %entryhash;
foreach my $entry ($lifttree->findnodes(q#//entry#)) {
	my $entryguid = $entry->getAttribute('guid');
	$entryhash{$entryguid} = $entry;
	if ($debug) {
		if ($entry->findnodes(q#./relation[@type='# . $sgrelname . q#']#)) {
			say $entry->findnodes(q#./relation[@type='# . $sgrelname . q#']#);
			}
		if ($entry->findnodes(q#./relation[@type='# . $plrelname . q#']#)) {
			say $entry->findnodes(q#./relation[@type='# . $plrelname . q#']#);
			}
		}
	}

my $mbrcnt=0;
my $mbrtotal=0;
foreach my $mbr ($genrelrt->findnodes('./Members/objsur')) {
	$mbrtotal++;
	my $mbrguid = $mbr->getAttribute('guid');
	my $lxrefrt = $rthash{$mbrguid};
	# say $lxrefrt;
	my @targets = $lxrefrt->findnodes('./Targets/objsur');
	next if (scalar ( @targets ) != 2); #only pairs not collections
	# Both targets must be in LIFT file
	my $target1guid = $targets[0]->getAttribute('guid');
	next if ! exists $entryhash{$target1guid};
	my $entry1 = $entryhash{$target1guid};
	my $target2guid = $targets[1]->getAttribute('guid');
	next if ! exists $entryhash{$target2guid};
	my $entry2 = $entryhash{$target2guid};

# next if entries have either singular or plural crossrefs already
	next if $entry1->findnodes(q#./relation[@type='# . $sgrelname . q#']#);
	next if $entry1->findnodes(q#./relation[@type='# . $plrelname . q#']#);
	next if $entry2->findnodes(q#./relation[@type='# . $sgrelname . q#']#);
	next if $entry2->findnodes(q#./relation[@type='# . $plrelname . q#']#);

# next if both don't have a just single Gnr relation
	my @rels1 = $entry1->findnodes(q#./relation[@type='# . $genrelname . q#']#);
	next if (scalar @rels1) != 1;
	my ($valen1) = $entry1->findnodes(q#./field[@type='Valency']/form/text/text()#);
	$valen1 = lc $valen1;

	my @rels2 = $entry2->findnodes(q#./relation[@type='# . $genrelname . q#']#);
	next if (scalar @rels2) != 1;
	my ($valen2) = $entry2->findnodes(q#./field[@type='Valency']/form/text/text()#);
	$valen2 = lc $valen2;

	#	and if one is Singular and other is Plural
	next if ! (("$valen1$valen2" eq "$sgabbrev$plabbrev"))
		|| (("$valen1$valen2" eq "$plabbrev$sgabbrev"));
		
	# as a subroutine input mbr node
	# Delete the Mbr node in the General list
	#    -but don't mess up the foreach command
	#    -maybe add to a list of mbrs to be deleted
	# create a new rt as singular ref
	# change the old Gnr ref to plural
	# add the singular & plural rts to their respective mbr lists.
	# Log the change as an Update
	# next

	say LOGFILE "pair:", $mbr;

	my ($gloss1) = $entry1->findnodes('./sense/gloss/text/text()');
	say LOGFILE "	entry1:", $valen1, " id:", $entry1->getAttribute('id');
	say LOGFILE "		gloss:$gloss1";
	
	my ($gloss2) = $entry2->findnodes('./sense/gloss/text/text()');
	say LOGFILE "	entry2:", $valen2, "  id:", $entry2->getAttribute('id');
	say LOGFILE "		gloss:$gloss2";

	$mbrcnt++;
	last if $mbrcnt > 30;
	}
say STDERR "Found $mbrcnt of $mbrtotal";
# maybe do mbr deletes from Gnr here.
die;
die "entries:". Dumper(%entryhash) ;

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
return qq#$formstring # . ($homographno ? qq#hm:$homographno #  : "") . qq#(guid="$guid")#;
}
