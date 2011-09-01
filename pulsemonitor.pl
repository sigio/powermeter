#!/usr/bin/perl -w


// (C) 2011 Mark Janssen <mark@sig-io.nl>
// Creative Commons - BY-CA 3.0


use RRDs;

my $pulsedev = "/dev/ttyUSB0";
open( PULSEDEV, '<', $pulsedev ) || die "Can't open serial port";

my $logfile = "pulse.log";
open( LOGFILE, '>>', $logfile ) || die "Can't open logfile";

{ my $ofh = select LOGFILE;
  $| = 1;
  select $ofh;
}
{ my $ifh = select PULSEDEV;
  $| = 1;
  select $ifh;
}


my ($second,$min,$hour,$mday,$mon,$year,$dummy);
my $ltime;
my ($lasthour,$lastmin);
my ($mincount,$hourcount) = 0;
($second,$min,$hour,$mday,$mon,$year,$dummy,$dummy,$dummy) = localtime(time);
$year += 1900;
$mon += 1;
$lasthour = $hour;
$lastmin = $min;

printf LOGFILE "%04d/%02d/%02d-%02d:%02d:%02d Started pulsemon\n", $year, $mon, $mday, $hour, $min, $second;

while(<PULSEDEV>)
{
	if ( $_ =~ /^PULSE/ )
	{
		$ltime = time;
		($second,$min,$hour,$mday,$mon,$year,$dummy,$dummy,$dummy) = localtime($ltime);
		
		$year += 1900;
		$mon += 1;

		if ( $min != $lastmin )
		{
			printf LOGFILE "Pulses this minute: %d\n", $mincount;
			$mincount=0;
			$lastmin = $min;
		}
		if ( $hour != $lasthour )
		{
			printf LOGFILE "Pulses this hour: %d\n", $hourcount;
			$hourcount=0;
			$lasthour = $hour;
		}

		$mincount++;	# Pulses this minute
		$hourcount++;	# Pulses this hour
		printf LOGFILE "%04d/%02d/%02d-%02d:%02d:%02d PULSE (%d/%d)\n", $year, $mon, $mday, $hour, $min, $second, $mincount, $hourcount;
		RRDs::update ("pulse.rrd", "--template", "ppm", "$ltime:$mincount");
		
	}
	else
	{
		printf LOGFILE "Unknown line: $_";
	}
}
