#!/usr/bin/perl -w
#
#   FragGeneScan: predicting genes in short and error-prone reads.
#	Copyright © 2010 Mina Rho, Yuzhen Ye and Haixu Tang.
#   Copyright © 2020 Bruno Cabado Lousa.
#	
#	This file is part of FragGeneScan.
#
#   FragGeneScan is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   FragGeneScan is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#	along with FragGeneScan.  If not, see <https://www.gnu.org/licenses/>.
#

use strict;
use Getopt::Long;

my $genome_file = "";
my $FGS_result = "";
my $FGS_whole = -1;
my $FGS_train_file = "";
my $command;
my $program = $0;
my $dir = substr($0, 0, length($0)-19);
my $train_file;
my $num_procs = 1;
my $starttime = time();
my $endtime;

GetOptions(
           'genome=s' => \$genome_file,
           'out=s' => \$FGS_result,
           'complete=s' => \$FGS_whole,
           'train=s' => \$FGS_train_file,
           'processes=s' => \$num_procs,
           );

if (length($genome_file)==0){
    print "ERROR: An input genome file was not specified.\n";
    print_usage();
    exit;
}elsif (! -e $genome_file){
    print "ERROR: The input genome file [$genome_file] does not exist.\n";
    print_usage();
    exit;
}

if (length($FGS_result) == 0 ){
    print "ERROR: An output file name was not specified.\n";
    print_usage();
    exit;
}

unless ($FGS_whole eq "1" || $FGS_whole eq "0"){
    print "ERROR: An incorrect value for the option -complete was entered.\n";
    print_usage();
    exit;
}  

$train_file = $dir."train/".$FGS_train_file;
if (length($FGS_train_file)==0){
    print  "ERROR: A file for model parameters was not specified.\n";
    print_usage();
    exit;
}elsif (! -e $train_file){
    print  "ERROR: The file for model parameter [$train_file] does not exist.\n";
    print_usage();
    exit;
}

if ($num_procs < 1)
{
   print "ERROR: processes number [$num_procs] error,\n";
   print_usage();
   exit;
}
$command = "mpirun -n ".$num_procs." ";
$command .= $dir."FragGeneScan";
$command .= " -s ".$genome_file;
$command .= " -o ".$FGS_result;
$command .= " -w ".$FGS_whole ;
$command .= " -t ".$FGS_train_file;
print "$command\n";
system($command); 

#system("mv ".$FGS_result." ".$FGS_result.".out");

$command = "awk 'BEGIN{print \"##gff-version 3\";} {s=substr(\$1,1,1); if (s==\">\") {seqid=substr(\$1,2);} else {s=split(\$0, t, \"\t\"); id=\"ID=\" seqid \"_\" t[1] \"_\" t[2] \"_\" t[3] \";product=predicted protein\"; print seqid \"\tFGS\tCDS\t\" t[1] \"\t\" t[2] \"\t.\t\" t[3] \"\t\" int(t[4]-1) \"\t\" id; }}' ".$FGS_result.".out > ".$FGS_result.".gff";
#use awk, Ye April 2016
#print "$command\n";
print "prepare gff file..\n";
system($command);

$endtime = time();
getElapsedTime($endtime - $starttime);

sub print_usage{
    print "USAGE: ./run_FragGeneScan.pl -genome=[seq_file_name] -out=[output_file_name] -complete=[1 or 0] -train=[train_file_name] (-processes=[number of processes; default 1])\n";
    print "       [seq_file_name]:    sequence file name including the full path\n";
    print "       [output_file_name]: output file name including the full path\n";
    print "       [1 or 0]:           1 if the sequence file has complete genomic sequences\n";
    print "                           0 if the sequence file has short sequence reads\n";
    print "       [train_file_name]:  file name that contains model parameters; this file should be in the \"train\" directory\n";
    print "                           Note that four files containing model parameters already exist in the \"train\" directory\n"; 
    print "                           [complete] for complete genomic sequences or short sequence reads without sequencing error\n";
    print "                           [sanger_5] for Sanger sequencing reads with about 0.5% error rate\n";
    print "                           [sanger_10] for Sanger sequencing reads with about 1% error rate\n";
    print "                           [454_10] for 454 pyrosequencing reads with about 1% error rate\n";
    print "                           [454_30] for 454 pyrosequencing reads with about 3% error rate\n";
    print "                           [illumina_5] for Illumina sequencing reads with about 0.5% error rate\n";
    print "                           [illumina_10] for Illumina sequencing reads with about 1% error rate\n";
    print "       [processes]:       number of processes used in FragGeneScan. Default 1.\n";
}

sub getElapsedTime
{
	my $input = $_[0];
	my $hour;
	my $min;
	my $sec;
	my $str;

	$sec = $input % 60;
	$input = int($input / 60);
	$min = $input % 60;
	$input = int($input / 60);
	$hour = $input;

	$str = "Time elapsed: ".$hour . " hours " . $min . " minutes and " . $sec . " seconds.\n";
	print $str;
}

