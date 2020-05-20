#!/usr/bin/perl -w 

use strict;

my $ROHFILE = $ARGV[0];
print STDERR "Reading $ROHFILE...\n";
open(ROH,"<$ROHFILE") or die $!;
   	
my %size; #ind->class->sum
my $pop;
my $ind;
my %ind2pop;
while (my $rohline = <ROH>){
	chomp $rohline;

	if($rohline =~ m/^track .+Ind: (.+) Pop:(.+) ROH.+/){
		$ind = $1;
		$pop = $2;
		$ind2pop{$ind} = $pop;
		$size{$ind}{'A'} = 0;
		$size{$ind}{'B'} = 0;
		$size{$ind}{'C'} = 0;
		$size{$ind}{'TOTAL'} = 0;
	}
	else{
		my ($chr, $start, $end, $class, $size, @junk) = split(/\s+/,$rohline);
		$size{$ind}{$class} += $size;
		$size{$ind}{'TOTAL'} += $size;
		
	}
}
close(ROH);
  	
my @indlist = keys %ind2pop;

print "pop A B C TOTAL\n";
for my $ind (@indlist){
    print $ind, " ", $ind2pop{$ind}, " ";
    print $size{$ind}{'A'}, " ";
    print $size{$ind}{'B'}, " ";
    print $size{$ind}{'C'}, " ";
    print $size{$ind}{'TOTAL'}, "\n";
}
