#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;



my $memory_total_gb = 0;
my $pg_version = 0;
my $shmmax = 0;


GetOptions (
    "m=s"   => \$memory_total_gb,  # Total memory
    "p=s"   => \$pg_version,       # postgres version
) or die "Error in command line arguments!\n";


if ( $memory_total_gb == 0 ) {
    $memory_total_gb = get_total_mem();
    if ( $memory_total_gb == 0 ) {
        die "We get zero total memory - set it manual via -m flag\n";
    }
}

if ( $pg_version == 0 ) {
    $pg_version = get_pg_version();
    if ( $pg_version == 0 ) {
        die "Cannot detect pg_version - set it manual via -p flag\n";
    }
} 

if ( $shmmax == 0 ) {
    $shmmax = get_shmmax();
    if ( $shmmax == 0 ) {
        die "Cannot get kernel.shmmax - exit\n";
    }
}

print "We have $memory_total_gb Gb total memory\n";
print "We have postgres $pg_version\n";
print "We have kernel.shmmax " . humanize($shmmax) ."\n";

# in kB
my %params = (
    'work_mem' => 1024 * $memory_total_gb,
    'maitenance_work_mem' => 32*1024 * $memory_total_gb,
    'fsync' => "off",
    'synchronous_commit' => "off",
    'wal_buffers' => 256 * $memory_total_gb,
    'checkpoint_completion_target' => 0.9,
    'effective_cache_size' => $memory_total_gb*1024*1024 / 2.0,
);

if ( $pg_version < 9.5 ) {
    $params{'checkpoint_segments'} = 32;
}
else {
    $params{'max_wal_size'} = 1536*1024;
}

if ( $pg_version < 9.4 ) {
    $params{'shared_buffers'} = $shmmax * 0.625;
}
else {
    $params{'shared_buffers'} = 128*1024 * $memory_total_gb;
}

print "\n\n";
for my $key ( sort keys %params ) {
    my $value;
    if ( $key ne 'checkpoint_completion_target' &&  $key ne 'checkpoint_segments' ) {
        $value = humanize($params{$key}); 
    }
    else {
        $value = $params{$key};
    }
    print "$key = $value\n";
}

### get mem

sub get_total_mem {
    open my $fh, "<", "/proc/meminfo" or die "Cannot open /proc/meminfo:$!\n";
    my $line = <$fh>; 
    close $fh;
    chomp $line;
    $line =~ s/\s+kB.*//;
    $line =~ s/.*\s+//;
    # Kb to Gb
    $line = $line/(1024.0*1024.0);
    return sprintf("%0.1f",$line);
}

sub humanize {
    my $number = shift;
    if ( $number !~ /^\d+(\.\d+)?$/ ) {
        return $number;
    }
    
    if ( $number < 1024 ) {
        return "${number}kB";
    }

    $number = sprintf("%0.0f",$number/1024);

    if ($number < 1024 ) {
        return sprintf("%0.0fMB",$number);
    } 
    else {
        return sprintf("%0.0fGB",$number/1024);
    }
    return $number;
}

sub get_pg_version {
    my $output = `pg_config --version 2>&1`;
    if ($?) {
        die "cannot run pg_config\n$output";
    }
    chomp $output;
    $output =~ s/.*\s+//;
    $output =~ s/^(\d+\.\d+).*/$1/;
    return $output;
}

sub get_shmmax {
    my $output = `sysctl -n kernel.shmmax 2>&1`;
    if ($?) {
        die "cannot get kernel.shmmax\n$output";
    }
    chomp $output;
    # Convert to KB
    $output = $output/1024.0;
    return sprintf("%0.0f",$output);
}
