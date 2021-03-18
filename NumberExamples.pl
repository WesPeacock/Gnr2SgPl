#!/usr/bin/perl
# You should probably use the related bash script to call this script, but you can use: 
my $USAGE = "Usage: $0 [--configfile NumberExamples.ini] [--section NumberExamples] [--debug] [--checkini]";

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
	'section:s'   => \(my $inisection = "NumberExamples"), # section of ini file to use
	'debug'       => \(my $debug = 0),
	'checkini'       => \(my $checkini = 0),
	) or die $USAGE;

use Config::Tiny;
 # ; NumberExamples.ini file looks like:
 # [NumberExamples]
 # FwdataIn=FwProject-before.fwdata
 # FwdataOut=FwProject.fwdata
 # NumberFieldname="Example Number"

my $config = Config::Tiny->read($configfile, 'crlf');

die "Couldn't find the INI file:$configfile\nQuitting" if !$config;
my $infilename = $config->{$inisection}->{FwdataIn};
my $outfilename = $config->{$inisection}->{FwdataOut};
my $numberfieldname = $config->{$inisection}->{NumberFieldname};

my $lockfile = $infilename . '.lock' ;
die "A lockfile exists: $lockfile\
Don't run $0 when FW is running.\
Run it on a copy of the project, not the original!\
I'm quitting" if -f $lockfile ;

die "config:". Dumper($config) if $checkini;

say "Processing fwdata file: $infilename";

my $fwdatatree = XML::LibXML->load_xml(location => $infilename);

my %rthash;
foreach my $rt ($fwdatatree->findnodes(q#//rt#)) {
	my $guid = $rt->getAttribute('guid');
	$rthash{$guid} = $rt;
	}

my @ExampleNumNodes = $fwdatatree->findnodes(q#//Custom[@name='# . $numberfieldname . q#']#);

die "No Custom $numberfieldname fields" unless @ExampleNumNodes;

my $examplecount = 0;
foreach my $ExampleNumNode (@ExampleNumNodes) {
	my ($LexExampleSentencert) = $ExampleNumNode->findnodes(q#./ancestor::rt#);
	my $LexExampleSentenceguid = $LexExampleSentencert->getAttribute('guid');
	say STDERR 'Found ', rtheader($LexExampleSentencert) if $debug;
	say STDERR "guid  $LexExampleSentenceguid" if $debug;
	my $LexSensert = traverseuptoclass($LexExampleSentencert, 'LexSense');
	say STDERR 'Found sense', rtheader($LexSensert) if $debug;
	my @prevsentences = $LexSensert->findnodes( q#./Examples/objsur[@guid="# . $LexExampleSentenceguid . q#"]/preceding-sibling::*# );
	# index-of in Xpath2 is nicer 
	my $index = scalar ( @prevsentences ) +1;
	say "index $index" if $debug;
	$ExampleNumNode->setAttribute('val', $index);
	$examplecount++;
	}

say STDERR "Renumbered $examplecount examples";
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
