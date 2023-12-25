#!/usr/bin/env perl
use strict;
use Getopt::Long;
use Storable qw(dclone freeze thaw);
use Data::Dumper;

my $G_USAGE = "
$0 --ids <ids> [--pipeline <nextflow_pipeline_to_use>] [--userid <user_id>] [--useremail <email_address>] [--pipeoutsub <pipeline_output_subfolder>]

--ids INTs        Sample LIMS id (separator , and range supported via ..)
--pipeline STR    nextflow pipeline to use in script
--userid STR      user id to use in job name
--useremail STR   email to set notification
--pipeoutsub STR  nextflow pipeline output subfolder (e.g. longread-map-merge-qc)
";

my $G_PROCESSED_SAMPLE_DIR = '/net/nwgc/vol1/data/processed/samples';
my $G_PIPELINE_SUBFOLDER = 'longread-map-merge-qc';
my $G_PIPELINE_SCRIPT = 'nwgc-longread-map-merge-qc.sh';
my $G_PIPELINE_YAML = 'nwgc-longread-map-merge-qc.yaml';
my $G_PIPELINE_DROPIN_SCRIPT = 'nwgc-longread-map-merge-qc.dropin.sh';
my $G_PIPELINE_DROPIN_YAML = 'nwgc-longread-map-merge-qc.dropin.yaml';
my $G_PIPELINE_BASECALLSETUP_SCRIPT = 'nwgc-longread-map-merge-qc.basecallsetup.sh';
my $G_PIPELINE_BASECALLSETUP_YAML = 'nwgc-longread-map-merge-qc.basecallsetup.yaml';

my $pipeline = '/net/nwgc/vol1/home/sseqwww/nwgc-longread-map-merge-qc-V4/main.nf';
my $G_userid = 'cheehong';
my $G_useremail = 'cheehong@uw.edu';

my $help = 0;
my $ids = '';
my $pipeline = '';
my $userid = '';
my $useremail = '';
my $pipeoutsub = '';

GetOptions (
"ids=s"       => \$ids,
"pipeline=s"  => \$pipeline,
"userid=s"    => \$userid,
"useremail=s" => \$useremail,
"pipeoutsub=s" => \$pipeoutsub,
"help!"       => \$help)
or die("Error in command line arguments\n$G_USAGE");

die "$G_USAGE" if ($help);

if ('' ne $pipeoutsub) {
    $G_PIPELINE_SUBFOLDER = $pipeoutsub;
}

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
    # create the dropin bash script
    # create the setup script
    my $srcShFile = sprintf("%s/%d/%s/%s", $G_PROCESSED_SAMPLE_DIR, $sampleId, $G_PIPELINE_SUBFOLDER, $G_PIPELINE_SCRIPT);
    my $srcYamlFile = sprintf("%s/%d/%s/%s", $G_PROCESSED_SAMPLE_DIR, $sampleId, $G_PIPELINE_SUBFOLDER, $G_PIPELINE_YAML);
    my $datetimestamp = getFileDateTimeStamp($srcShFile);

    if (0==isSamplifyManifest($srcShFile)) {
        my $destDropInShFile = sprintf("%s/%d/%s/%s", $G_PROCESSED_SAMPLE_DIR, $sampleId, $G_PIPELINE_SUBFOLDER, $G_PIPELINE_DROPIN_SCRIPT);
        my $destDropInYamlFile = sprintf("%s/%d/%s/%s", $G_PROCESSED_SAMPLE_DIR, $sampleId, $G_PIPELINE_SUBFOLDER, $G_PIPELINE_DROPIN_YAML);
        writeDropInScript ($srcShFile, $destDropInShFile);
        print "Sample $sampleId : $destDropInShFile written.\n";
        writeDropInConfig ($srcYamlFile, $destDropInYamlFile);
        print "Sample $sampleId : $destDropInYamlFile written.\n";

        my $destBasecallSetupShFile = sprintf("%s/%d/%s/%s", $G_PROCESSED_SAMPLE_DIR, $sampleId, $G_PIPELINE_SUBFOLDER, $G_PIPELINE_BASECALLSETUP_SCRIPT);
        my $destBasecallSetupYamlFile = sprintf("%s/%d/%s/%s", $G_PROCESSED_SAMPLE_DIR, $sampleId, $G_PIPELINE_SUBFOLDER, $G_PIPELINE_BASECALLSETUP_YAML);
        writeBasecallSetupScript ($srcShFile, $destBasecallSetupShFile);
        print "Sample $sampleId : $destBasecallSetupShFile written.\n";
        writeBasecallSetupConfig ($srcYamlFile, $destBasecallSetupYamlFile);
        print "Sample $sampleId : $destBasecallSetupYamlFile written.\n";

        if (1==1) {
            # everything successful,
            # we rename original .sh and .yaml with date.time stamp
            # we mv dropin.sh and dropin.yaml as .sh and .yaml
            my $newSrcShFile = $srcShFile.'.'.$datetimestamp;
            my $newSrcYamlFile = $srcYamlFile.'.'.$datetimestamp;
            rename($srcShFile, $newSrcShFile) || die ( "BACKUP: Error renaming $srcShFile --> $newSrcShFile" );
            rename($srcYamlFile, $newSrcYamlFile) || die ( "BACKUP: Error renaming $srcYamlFile --> $newSrcYamlFile" );
            rename($destDropInShFile, $srcShFile) || die ( "SWITCH: Error renaming $destDropInShFile --> $srcShFile" );
            rename($destDropInYamlFile, $srcYamlFile) || die ( "SWITCH: Error renaming $destDropInYamlFile --> $srcYamlFile" );

            print "Sample $sampleId : original backup with suffix tag $datetimestamp\n";
            print "Sample $sampleId : dropin swapped.\n";
            print "-\n";
        }

    } else {
        print "Sample $sampleId script ($datetimestamp) is not the copy generated from Samplify. Skipped.\n";
    }
}

exit 0;

sub getFileDateTimeStamp {
    my ($file) = @_;
    my $mtime = (stat($file))[9];
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($mtime);
    return sprintf "%04d%02d%02d.%02d%02d%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec;
}

sub isSamplifyManifest {
    my ($file) = @_;
    # PIPELINE_NAME=nwgc-longread-map-merge-qc
    # will inject WRITER=manualV4
    my $status = 0;
    open INFILE, $file || die "Fail to open $file\n$!\n";
    while (<INFILE>) {
        if (/^PIPELINE_NAME=/) {
            chomp();
            if ("PIPELINE_NAME=nwgc-longread-map-merge-qc" eq $_) {
                $status = 0;
            } else {
                $status = 1;
            }
        } elsif (/^WRITER=/) {
            $status = 1;
            last;
        }
    }
    close INFILE;
    return $status;
}

sub isLocalPipeline {
    my ($value) = @_;
    if ($value =~ /\//) {
        return 0;
    } else {
        return 1;
    }
}

sub writeDropInScript {
    my ($srcFile, $destFile) = @_;
    open INFILE, $srcFile || die "Fail to open $srcFile\n$!\n";
    open OUTFILE, ">$destFile" || die "Fail to open $destFile\n$!\n";
    my $localPipeline = isLocalPipeline($pipeline);
    while (<INFILE>) {
        if (/^#\$\s+/) {
            if (/^#\$\s+\-M\s+/) {
                if ('' eq $pipeline) {
                    # basecall is a hidden process; do NOT confuse Samplilfy user
                    print OUTFILE "#\$ -M $G_userid\n";
                } else {
                    print OUTFILE "#\$ -M ",('' ne $userid) ? $userid : $G_userid,"\n";
                }
            } elsif (/^#\$\s+\-N\s+/) {
                chomp();
                $_ .= '_dropin';
                print OUTFILE $_,"\n";
            } else {
                print OUTFILE $_;
            }
        } elsif (/^\w+=.+/) {
            if (/^USER_EMAIL=/) {
                if ('' eq $pipeline) {
                    # basecall is a hidden process; do NOT confuse Samplilfy user
                    # print OUTFILE $_, "\n";
                    print OUTFILE "USER_EMAIL=",$G_useremail,"\n";
                } else {
                    print OUTFILE "USER_EMAIL=",('' ne $useremail) ? $useremail : $G_useremail,"\n";
                }
            } elsif (/^PIPELINE_NAME=/) {
                # TODO:
                if ('' eq $pipeline) {
                    print OUTFILE $_;
                } else {
                    printf OUTFILE "PIPELINE_NAME=%s\n", $pipeline;
                }
            } elsif (/^PIPELINE_YAML=/) {
                # printf OUTFILE "PIPELINE_YAML=%s\n", $G_PIPELINE_DROPIN_YAML;
                print OUTFILE $_;
            } elsif (/^JOB_NAME=/) {
                chomp();
                $_ .= '_dropin';
                print OUTFILE $_,"\n";
            } else {
                print OUTFILE $_;
            }
        } else {
            if (0==$localPipeline) {
                if (/\s*\-r\s+\$PIPELINE_VERSION/) {
                    # skipping versioning as none is available for local pipeline
                } else {
                    print OUTFILE $_;
                }
            } else {
                print OUTFILE $_;
            }
        }
    }
    print OUTFILE "\n\n";
    print OUTFILE "# drop-in replacement for Samplify merge button action\n";
    print OUTFILE "# parameters are all as-is\n";
    print OUTFILE "# user info changed, rabbit MQ turn off - prevent updates\n";

    close INFILE;
    close OUTFILE;
}

# TODO: override userid and email?
#       'cos user does not know about additional basecalling
sub writeDropInConfig {
    my ($srcFile, $destFile) = @_;

    open INFILE, $srcFile || die "Fail to open $srcFile\n$!\n";
    open OUTFILE, ">$destFile" || die "Fail to open $destFile\n$!\n";
    my $fastqToBam = 0;
    while (<INFILE>) {
        if (/^#/) {
            print OUTFILE $_;
        } elsif (/^[0-9A-Za-z]/) {
            if (/\w+\:\s*.+/) {
                $fastqToBam = 0;
                chomp();
                my ($key, $value) = $_ =~ /(\w+)\:\s*(.+)/;
                if ("userId" eq $key) {
                    if ('' eq $pipeline) {
                        # basecall is a hidden process; do NOT confuse Samplilfy user
                        # print OUTFILE $_, "\n";
                        print OUTFILE "userId: \"",$G_userid,"\"\n";
                    } else {
                        print OUTFILE "userId: \"",('' ne $userid) ? $userid : $G_userid,"\"\n";
                    }
                } elsif ("userEmail" eq $key) {
                    if ('' eq $pipeline) {
                        # basecall is a hidden process; do NOT confuse Samplilfy user
                        # print OUTFILE $_, "\n";
                        print OUTFILE "userEmail: \"",$G_useremail,"\"\n";
                    } else {
                        print OUTFILE "userEmail: \"",('' ne $useremail) ? $useremail : $G_useremail,"\"\n";
                    }
                } elsif ("rabbitHost" eq $key) {
                    if ('' eq $pipeline) {
                        print OUTFILE $_, "\n";
                    } else {
                        print OUTFILE "rabbitHost: \"\"\n";
                    }
                } elsif ("registration_url" eq $key) {
                    if ('' eq $pipeline) {
                        print OUTFILE $_, "\n";
                    } else {
                        print OUTFILE "registration_url: \"\"\n";
                    }
                } else {
                    print OUTFILE $_, "\n";
                }
            } elsif (/\w+\:\s*$/) {
                $fastqToBam = 0;
                chomp();
                my ($key, $value) = $_ =~ /(\w+)\:\s*/;
                if ('ontFastqFolders' eq $key) {
                    print OUTFILE "ontBamFolders:\n";
                    $fastqToBam = 1;
                } else {
                    print OUTFILE $_, "\n";
                }
            } else {
                print OUTFILE $_;
            }
        } else {
            if (/^\s+\-\s+/) {
                if (0!=$fastqToBam) {
                    chomp();
                    if (/\/fastq_pass"$/) {
                        s/\/fastq_pass"$/\/bam_pass"/;
                    }
                    print OUTFILE $_, "\n";
                } else {
                    print OUTFILE $_;
                }
            } else {
                print OUTFILE $_;
            }
        }
    }
    print OUTFILE "\n\n";
    print OUTFILE "# drop-in replacement for Samplify merge button action\n";
    print OUTFILE "# parameters are all as-is\n";
    print OUTFILE "# email and pipeline re-configured\n";

    close INFILE;
    close OUTFILE;
}

# override userid and email?
# 'cos user does not know about additional basecalling
sub writeBasecallSetupScript {
    my ($srcFile, $destFile) = @_;
    open INFILE, $srcFile || die "Fail to open $srcFile\n$!\n";
    open OUTFILE, ">$destFile" || die "Fail to open $destFile\n$!\n";
    my $localPipeline = isLocalPipeline($pipeline);
    while (<INFILE>) {
        if (/^#\$\s+/) {
            if (/^#\$\s+\-M\s+/) {
                if ('' eq $pipeline) {
                    # basecall is a hidden process; do NOT confuse Samplilfy user
                    print OUTFILE "#\$ -M $G_userid\n";
                } else {
                    print OUTFILE "#\$ -M ",('' ne $userid) ? $userid : $G_userid,"\n";
                }
            } elsif (/^#\$\s+\-N\s+/) {
                chomp();
                $_ .= '_basecallsetup';
                print OUTFILE $_,"\n";
            } else {
                print OUTFILE $_;
            }
        } elsif (/^\w+=.+/) {
            if (/^USER_EMAIL=/) {
                if ('' eq $pipeline) {
                    # basecall is a hidden process; do NOT confuse Samplilfy user
                    # print OUTFILE $_, "\n";
                    print OUTFILE "USER_EMAIL=",$G_useremail,"\n";
                } else {
                    print OUTFILE "USER_EMAIL=",('' ne $useremail) ? $useremail : $G_useremail,"\n";
                }
            } elsif (/^PIPELINE_NAME=/) {
                # TODO:
                if ('' eq $pipeline) {
                    print OUTFILE $_;
                } else {
                    printf OUTFILE "PIPELINE_NAME=%s\n", $pipeline;
                }
            } elsif (/^PIPELINE_YAML=/) {
                printf OUTFILE "PIPELINE_YAML=%s\n", $G_PIPELINE_BASECALLSETUP_YAML;
            } elsif (/^JOB_NAME=/) {
                chomp();
                $_ .= '_basecallsetup';
                print OUTFILE $_,"\n";
            } else {
                print OUTFILE $_;
            }
        } else {
            if (0==$localPipeline) {
                if (/\s*\-r\s+\$PIPELINE_VERSION/) {
                    # skipping versioning as none is available for local pipeline
                } else {
                    print OUTFILE $_;
                }
            } else {
                print OUTFILE $_;
            }
        }
    }
    close INFILE;
    close OUTFILE;
}

# override userid and email?
# 'cos user does not know about additional basecalling
sub writeBasecallSetupConfig {
    my ($srcFile, $destFile) = @_;
    
    open INFILE, $srcFile || die "Fail to open $srcFile\n$!\n";
    open OUTFILE, ">$destFile" || die "Fail to open $destFile\n$!\n";
    my $fastqToBam = 0;
    while (<INFILE>) {
        if (/^#/) {
            print OUTFILE $_;
        } elsif (/^[0-9A-Za-z]/) {
            if (/\w+\:\s*.+/) {
                $fastqToBam = 0;
                chomp();
                my ($key, $value) = $_ =~ /(\w+)\:\s*(.+)/;
                if ("userId" eq $key) {
                    if ('' eq $pipeline) {
                        # basecall is a hidden process; do NOT confuse Samplilfy user
                        # print OUTFILE $_, "\n";
                        print OUTFILE "userId: \"",$G_userid,"\"\n";
                    } else {
                        print OUTFILE "userId: \"",('' ne $userid) ? $userid : $G_userid,"\"\n";
                    }
                } elsif ("userEmail" eq $key) {
                    if ('' eq $pipeline) {
                        # basecall is a hidden process; do NOT confuse Samplilfy user
                        # print OUTFILE $_, "\n";
                        print OUTFILE "userEmail: \"",$G_useremail,"\"\n";
                    } else {
                        print OUTFILE "userEmail: \"",('' ne $useremail) ? $useremail : $G_useremail,"\"\n";
                    }
                } elsif ("rabbitHost" eq $key) {
                    if ('' eq $pipeline) {
                        print OUTFILE $_, "\n";
                    } else {
                        print OUTFILE "rabbitHost: \"\"\n";
                    }
                } elsif ("registration_url" eq $key) {
                    if ('' eq $pipeline) {
                        print OUTFILE $_, "\n";
                    } else {
                        print OUTFILE "registration_url: \"\"\n";
                    }
                } else {
                    print OUTFILE $_, "\n";
                }
            } elsif (/\w+\:\s*$/) {
                $fastqToBam = 0;
                chomp();
                my ($key, $value) = $_ =~ /(\w+)\:\s*/;
                if ('ontFastqFolders' eq $key) {
                    print OUTFILE "ontBamFolders:\n";
                    $fastqToBam = 1;
                } else {
                    print OUTFILE $_, "\n";
                }
            } else {
                print OUTFILE $_;
            }
        } else {
            if (/^\s+\-\s+/) {
                if (0!=$fastqToBam) {
                    chomp();
                    if (/\/fastq_pass"$/) {
                        s/\/fastq_pass"$/\/bam_pass"/;
                    }
                    print OUTFILE $_, "\n";
                } else {
                    print OUTFILE $_;
                }
            } else {
                print OUTFILE $_;
            }
        }
    }
    print OUTFILE "\n\n";
    print OUTFILE "# ont basecall setup and basecalling only\n";
    print OUTFILE "ontSetupBasecall: true\n";

    close INFILE;
    close OUTFILE;
}
