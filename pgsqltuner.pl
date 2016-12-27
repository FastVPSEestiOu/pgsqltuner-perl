#!/usr/bin/perl
#
# pgsqltuner.pl
# High Performance PostgreSQL Tuning Script
# Copyright (C) 2016 Sergei A Mamonov for fastvps.ru - mrqwer88@gmail.com
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as published by
# the Free Software Foundation
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# This project would not be possible without help from Denis Maksimov.
# 
# Inspired by http://mysqltuner.com/ ( http://github.com/major/MySQLTuner-perl )
# 

use strict;
use warnings;

use Getopt::Long;


my $rounding_limit_mb = 256;

my $memory_total_gb = 0;
my $pg_version = 0;
my $shmmax = 0;
my $help = 0;

my $usage = "pgsqltuner.pl - is a script written in Perl that will assist you with your postgres configuration\n
Usage:\n\tpgsqltuner.pl [ -m MEMORY ] [ -p PG_VERSION ] [ -h|--help ]
\t\t-m - set total memory in Gb
\t\t-p - set postgres version like 9.5
\t\t-h - show this message\n";

GetOptions (
    "m=f"    => \$memory_total_gb,  # Total memory
    "p=f"    => \$pg_version,       # postgres version
    "h|help" => \$help,
) or die "Error in command line arguments!\n$usage\n";

### MAIN ###

if ( $help ) {
    print $usage,"\n";
    exit 0;
}

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
    'maintenance_work_mem' => 32*1024 * $memory_total_gb,
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

if ( $pg_version < 9.3 ) {
    $params{'shared_buffers'} = $shmmax * 0.625;
}
else {
    $params{'shared_buffers'} = 128*1024 * $memory_total_gb;
}

print "\n\n#### Recommendations ####\n";
for my $key ( sort keys %params ) {
    my $value;
    if ( $key ne 'checkpoint_completion_target' &&  $key ne 'checkpoint_segments' ) {
        $value = humanize_for_config($params{$key}); 
    }
    else {
        $value = $params{$key};
    }
    print "$key = $value\n";
}

### OUR SUBS ###

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

    $number = sprintf("%0.1f", $number/1024);

    if ($number < 1024 ) {
        return sprintf("%0.1fMB", $number);
    } 
    else {
        return sprintf("%0.1fGB", $number/1024);
    }
    return $number;
}

sub humanize_for_config {
    my $number = shift;
    if ( $number !~ /^\d+(\.\d+)?$/ ) {
        return $number;
    }
    
    if ( $number < 1024 ) {
        return "${number}kB";
    }

    $number = sprintf("%0.0f", $number/1024);

    if ($number < 1024 ) {
        return sprintf("%0.0fMB", $number);
    } 
    else {
        my $mod = $number % 1024;
        if ( $mod < $rounding_limit_mb ) {
            return sprintf("%0.0fGB", $number/1024);
        } else {
            return sprintf("%0.0fMB", $number);
        }
    }
    return $number;
}

sub get_pg_version_pg_config {
    my $output = `pg_config --version 2>&1`;
    if ($?) {
        my $warn_message = "cannot run pg_config\n";
        if ( defined $output) {
            $warn_message .= "$output\n";
        }
        warn $warn_message;
        return 0;
    }
    chomp $output;
    $output =~ s/.*\s+//;
    $output =~ s/^(\d+\.\d+).*/$1/;
    return $output;
}

sub get_pg_version_ps {
    my @output = `ps eaxo command 2>&1`;
    if ($?) {
        warn 'cannot run ps';
        return 0;
    }
    # Get version from linee
    # /usr/lib/postgresql/9.1/bin/postgres -D /var/lib/postgresql/9.1/main -c config_file=/etc/postgresql/9.1/main/postgresql.confPG_GRANDPARENT_PID=2617 PGLOCALEDIR=/usr/share/locale PGSYSCONFDIR=/etc/postgresql-common PWD=/var/lib/postgresql PGDATA=/var/lib/postgresql/9.1/main
    # /usr/pgsql-9.2/bin/postmaster -p 5432 -D /var/lib/pgsql/9.2/data HOSTNAME=CentOS-60-64-ISPLite SHELL=/bin/bash  ....
    for my $line ( @output) {
        if ( $line =~ m(bin/(postgres|postmaster)) ) {
            if ( $line =~ /(\d+\.\d+)/ ) {
                if ( defined $1 ) {
                    return $1;
                } else {
                    return 0;
                }
            } else {
                return 0;
            }
        }
    }
    return 0;
}

sub get_pg_version {
    my $version = get_pg_version_ps();
    if ( $version ) {
        return $version;
    }
    
    return get_pg_version_pg_config();
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
