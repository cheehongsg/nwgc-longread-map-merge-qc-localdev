#!/usr/bin/env perl
use strict;
use Getopt::Long;
use Storable qw(dclone freeze thaw);
use Data::Dumper;

###
# set up the move in parallel scripts
###

my $G_USAGE = "
$0 --ids <ids>

--ids INTs       Sample LIMS id (separator , and range supported via ..)
";

my $G_PROCESSED_SAMPLE_DIR = '/net/nwgc/vol1/data/processed/samples';

my $help = 0;
my $ids = '';

GetOptions (
"ids=s"       => \$ids,
"help!"       => \$help)
or die("Error in command line arguments\n$G_USAGE");

die "$G_USAGE" if ($help);
	
my @sampleIds = ();
if (my($number) = ($ids =~ /^(\d+)$/)) {
    push(@sampleIds, $number);
} elsif (my($start, $end) = ($ids =~ /^(\d+)\.\.(\d+)$/)) {
    if ($start < $end) {
        push(@sampleIds, $start..$end);
    } else {
        push(@sampleIds, reverse($end..$start));
    }
} elsif (my($first, $others) = ($ids =~ /^(\d+)[\s,]((?:\d+[\s,])*\d+)$/)) {
    push(@sampleIds, $first, split(/[\s,]/, $others));
} else {
    die "invalid argument for --ids option: $ids\n";
}

foreach my $sampleId (@sampleIds) {
    # create a copy of bash script to move the files as quickly as possible

    my $sampleDir = sprintf("/net/nwgc/vol1/nobackup/cheehong/onttest/longread-map-merge-qc-V2/%s/longread-map-merge-qc/ont/", $sampleId);
    opendir my $dir, $sampleDir or die "Cannot open directory $sampleDir: $!\n";
    my @runAcqFolders = grep { /^2023/ } readdir $dir;
    closedir $dir;

    foreach my $runAcqFolder (@runAcqFolders) {
        my $runAcqFPN = sprintf("%s%s", $sampleDir, $runAcqFolder);

        print "# $sampleId - $runAcqFolder\n";
        print "cd $runAcqFPN\n";

        my $name = 'ontmv_s1';
        my $fname = sprintf("%s.sh", $name);
        my $ofile = sprintf("%s/%s", $runAcqFPN, $fname);
        my $command = "mv nwgc-*.sh .nextflow* monitor logs qc *.whole_genome.summary.tsv.gz *.yaml /net/nwgc/vol1/data/processed/samples/$sampleId/ont/$runAcqFolder/";
        writeScript($ofile, $runAcqFPN, $name, $command);
        # print "qsub $fname\n";

        my $name = 'ontmv_s2';
        my $fname = sprintf("%s.sh", $name);
        my $ofile = sprintf("%s/%s", $runAcqFPN, $fname);
        my $command = "mv mapped_pass_sup /net/nwgc/vol1/data/processed/samples/$sampleId/ont/$runAcqFolder/";
        writeScript($ofile, $runAcqFPN, $name, $command);
        # print "qsub $fname\n";

        my $name = 'ontmv_s3';
        my $fname = sprintf("%s.sh", $name);
        my $ofile = sprintf("%s/%s", $runAcqFPN, $fname);
        my $command = "mv bam_fail_sup /net/nwgc/vol1/data/processed/samples/$sampleId/ont/$runAcqFolder/";
        writeScript($ofile, $runAcqFPN, $name, $command);
        # print "qsub $fname\n";

        my $name = 'ontmv_s4';
        my $fname = sprintf("%s.sh", $name);
        my $ofile = sprintf("%s/%s", $runAcqFPN, $fname);
        my $command = "mv bam_pass_sup /net/nwgc/vol1/data/processed/samples/$sampleId/ont/$runAcqFolder/";
        writeScript($ofile, $runAcqFPN, $name, $command);
        # print "qsub $fname\n";

        my $name = 'ontmv_s5';
        my $fname = sprintf("%s.sh", $name);
        my $ofile = sprintf("%s/%s", $runAcqFPN, $fname);
        my $command = "mv fast5_to_pod5 /net/nwgc/vol1/data/processed/samples/$sampleId/ont/$runAcqFolder/";
        writeScript($ofile, $runAcqFPN, $name, $command);
        # print "qsub $fname\n";

        print "echo \$(date); for i in ontmv_s?.sh ; do qsub \${i} ; done\n";
    }
}

exit 0;



sub writeScript {
    my ($file, $runAcqFPN, $name, $command) = @_;

    open OUTFILE, ">$file" || die "Fail to open $file\n$!\n";

    print OUTFILE "#!/bin/bash\n";
    print OUTFILE "#\$ -P dna\n";
    print OUTFILE "#\$ -l d_rt=2:0:0\n";
    print OUTFILE "#\$ -S /bin/bash\n";
    print OUTFILE "#\$ -M cheehong\@uw.edu\n";
    print OUTFILE "#\$ -m as\n";
    print OUTFILE "#\$ -l mfree=2G\n";
    print OUTFILE "#\$ -r yes\n";
    print OUTFILE "#\$ -R yes\n";
    print OUTFILE "#\$ -e $runAcqFPN/\n";
    print OUTFILE "#\$ -o $runAcqFPN/\n";
    print OUTFILE "#\$ -N $name\n";
    print OUTFILE "\n";
    print OUTFILE "set -o xtrace\n";
    print OUTFILE "set -o nounset\n";
    print OUTFILE "set -o errexit\n";
    print OUTFILE "\n";
    print OUTFILE "cd $runAcqFPN\n";
    print OUTFILE "$command\n";

    close OUTFILE;
}
