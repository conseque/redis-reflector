#!/usr/bin/perl

use IPC::Open2;

local(*OL, *IL); $slaveconnector  =open2(*OL, *IL, "socat TCP4-LISTEN:63799 -");
local(*O1, *I1); $master1connector=open2(*O1, *I1, "socat - TCP4:127.0.0.1:63791");
local(*O2, *I2); $server2connector=open2(*O2, *I2, "socat - TCP4:127.0.0.1:63792");
local(*AOF); open AOF, "/var/lib/redis/b.aof"; while (<AOF>) { $aof.=$_ }

my $server1reader=fork();	if (!$server1reader)	{ while (<O1>)	{ &sendtoclient($_,1) } }
my $server2reader=fork();	if (!$server2reader)	{ while (<O2>)	{ &sendtoclient($_,2) if $_ !~ /^REDIS/ } }
my $clientreader=fork();	if (!$clientreader)	{ while (<OL>)	{ &sendtoserver($_)   } }
							  while (<>)	{ &logtoconsole($_)   }
										# parenthread becomes consolereader

sub sendtoclient	{ print "S$_[1]=>C:\t";	$line = $_[0]; print $line; print IL $line; }
sub sendtoserver	{ print "C=>S1:\t";	$line = $_[0]; print $line; print I1 $line; sleep(15) if $line =~ /SYNC/;
			  print "C=>S2:\t";	$line = $_[0]; print $line; print I2 $line; }
sub logtoconsole	{ print "CMMNT:\t";	$line = $_[0]; print $line; print IL $aof if $line =~ /aof/ }

