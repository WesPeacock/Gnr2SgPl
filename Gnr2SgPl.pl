#!/usr/bin/perl
# You should probably use the related bash script to call this script, but you can use: 
my $USAGE = "Usage: $0 [--configfile Gnr2SgPl.ini] [--section Gnr2SgPl] [--debug] [--checkini]";

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

my ($genrelrt) = $fwdatatree->findnodes(q#//AUni[text()='# . $genrelname . q#']/ancestor::rt[@class='LexRefType']#);

my ($sgrelrt) = $fwdatatree->findnodes(q#//AUni[text()='# . $sgrelname . q#']/ancestor::rt[@class='LexRefType']#);

my ($plrelrt) = $fwdatatree->findnodes(q#//AUni[text()='# . $plrelname . q#']/ancestor::rt[@class='LexRefType']#);

say STDERR "Loading LIFT file: $liftfilename";
my $lifttree = XML::LibXML->load_xml(location => $liftfilename);

my %entryhash;
foreach my $entry ($lifttree->findnodes(q#//entry#)) {
	my $entryguid = $entry->getAttribute('guid');
	$entryhash{$entryguid} = $entry;
	}

# say LOGFILE "General LexReftype:";
# say LOGFILE $genrelrt;
my $mbrcnt=0;
foreach my $mbr ($genrelrt->findnodes('./Members/objsur')) {
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

	say LOGFILE "mbr:", $mbr;
	say LOGFILE "	entry1 id:", $entry1->findnodes('./@id');
	say LOGFILE "	entry2 id:", $entry2->findnodes('./@id');

	$mbrcnt++;
	die if $mbrcnt > 3;
	}

=pod
say "Singular LexReftype:";
say $sgrelrt;
say "Plural LexReftype:";
say $plrelrt;

=cut

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
