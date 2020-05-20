#!/usr/bin/perl -w

use strict;

my $file = $ARGV[0];
open(FIN,"<",$file) or die $!;
my $header = <FIN>;
while(defined(my $line = <FIN>)){
	chomp $line;
	my ($chr, $pos, @data) = split(/\s+/,$line);
	my $n = @data;
	my $freq = 0;
	for my $i (@data){
		$freq += $i;
	}
	print $chr, "\t", $pos, "\t", $freq, "\t", $n, "\t", ($freq/$n), "\n";
}
close(FIN);
