#!/usr/bin/perl
# You should probably use the related bash script to call this script, but you can use: 
my $USAGE = "Usage: $0 [--configfile Gnr2SgPl.ini] [--section Gnr2SgPl] [--debug] [--checkini] [--simple] [--gnrdmp] [--sgpldmp]";
# debug -- dump debugging information
# checkini -- quit after proscessing configfile
# simple -- each member of the selected pair has no other Gnr relation other than the SG/PL one
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
	'simple'       => \(my $simple = 0),
	) or die $USAGE;

use Config::Tiny;
 # ; Gnr2SgPl.ini file looks like:
 # [Gnr2SgPl]
 # FwdataIn=FwProject-before.fwdata
 # #FwdataOut is used by FixSgPl.pl
 # FwdataOut=FwProject.fwdata
 # SgPlFieldname=Valency
 # PluralRelationName=Plural
 # SingularRelationName=Singular
 # LiftFile=lift.lift
 # LogFile=Gnr2SgPl.log

my $config = Config::Tiny->read($configfile, 'crlf');

die "Couldn't find the INI file:$configfile\nQuitting" if !$config;
my $infilename = $config->{$inisection}->{FwdataIn};
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

=pod
# Log file looks like:
# <?xml version="1.0" encoding="UTF-8" ?>
# <pairs>
# <pair guid="00fe7802-9317-4bf1-86a2-4bc7e300a85a" entry1id=
# 		"SG_kób_263aa645-97e9-45ac-9a1d-37daabfe64ef" entry1gloss=
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

say STDERR "Loading LIFT file: $liftfilename";
my $lifttree = XML::LibXML->load_xml(location => $liftfilename);

my %entryhash;
foreach my $entry ($lifttree->findnodes(q#//entry#)) {
	my $entryguid = $entry->getAttribute('guid');
	$entryhash{$entryguid} = $entry;
	if ($debug) {
		if ($entry->findnodes(q#./relation[@type='# . $sgrelname . q#']#)) {
			say $entry->findnodes(q#./relation[@type='# . $sgrelname . q#']#);
=pod
			my ($s) = $entry->findnodes(q#./field[@type='Valency']/form/text/text()#);
			say "lift:", uc $s;
			my $temprt =  $rthash{$entry->getAttribute('guid')};
			($s) = $temprt->findnodes(q#./Custom[@name='Valency']/AStr/Run/text()#);
			say "fwdata:", uc $s;
=cut
			}
		if ($entry->findnodes(q#./relation[@type='# . $plrelname . q#']#)) {
			say $entry->findnodes(q#./relation[@type='# . $plrelname . q#']#);
			}
		}
	}

# header of log file
say LOGFILE '<?xml version="1.0" encoding="UTF-8" ?>';
say LOGFILE '<pairs>';
say LOGFILE q#<!--  DON'T EDIT ANYTHING ABOVE THIS LINE -->#, "\n\n" ;

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

	my ($valen1) = $entry1->findnodes(q#./field[@type='Valency']/form/text/text()#);
	$valen1 = uc $valen1;
	my ($valen2) = $entry2->findnodes(q#./field[@type='Valency']/form/text/text()#);
	$valen2 = uc $valen2;

	#	next unless one is Singular and other is Plural
	next unless ("$valen1$valen2" eq "$sgabbrev$plabbrev")
		|| ("$valen1$valen2" eq "$plabbrev$sgabbrev");

# In simple mode next if either don't have just a single Gnr relation
	if ($simple) {
		my @rels = $entry1->findnodes(q#./relation[@type='# . $genrelname . q#']#);
		next if (scalar @rels) != 1;
		@rels = $entry2->findnodes(q#./relation[@type='# . $genrelname . q#']#);
		next if (scalar @rels) != 1;
		}

	print LOGFILE q#<pair guid="#, $mbr->getAttribute('guid');
	my ($gloss1) = $entry1->findnodes('./sense/gloss/text/text()');
	say LOGFILE q#" entry1id=#;
	say LOGFILE qq#	"$valen1\_#, $entry1->getAttribute('id'), q#" entry1gloss=#;
	say LOGFILE qq#	"$gloss1" entry2id=\n#;

	my ($gloss2) = $entry2->findnodes('./sense/gloss/text/text()');
	say LOGFILE qq#	"$valen2\_#, $entry2->getAttribute('id'), q#" entry2gloss=#;
	say LOGFILE qq#	"$gloss2"/>\n#;

	$mbrcnt++;
	last if $mbrcnt > 30;
	}

# footer of log
say LOGFILE q#<!--  DON'T EDIT ANYTHING BELOW THIS LINE -->#;
say LOGFILE '</pairs>';

say STDERR "Found $mbrcnt of $mbrtotal";

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
