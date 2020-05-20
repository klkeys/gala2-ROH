#!/usr/bin/perl -w 

use strict;

my $orderFile = $ARGV[0];
my $sortFile = $ARGV[1];
#my $outfile = $sortFile;

#if($outfile =~ s/\.txt$/\.sorted\.txt/g){
#	print STDERR "Output file $outfile\n";
#}
#else{
#	$outfile .= ".sorted";
#	print STDERR "Output file $outfile\n";
#}

open(FIN,"<",$orderFile) or die $!;
my @order;
while(defined(my $line = <FIN>)){
	chomp $line;
	push(@order,$line);
}
close(FIN);


open(FIN,"<",$sortFile) or die $!;
my $header = <FIN>;
my %lines;
while(defined(my $line = <FIN>)){
	chomp $line;
	my ($id,$junk) = split(/\s+/,$line,2);
	$lines{$id} = $line;
}
close(FIN);

#open(FOUT,">",$outfile) or die $!;
print $header;
for my $id (@order){
	if(exists $lines{$id}){
		print $lines{$id}, "\n";
	}
}
#close(FOUT);
