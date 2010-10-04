#!/usr/bin/perl -w
use strict;
require File::Spec;

our %conf;
$conf{'basedir'} = get_basedir();
$conf{'emptydir'} = "$conf{'basedir'}/__emptydir/";

require 'dhsnapshot.conf';

my $lowest_interval = 'daily';
my %rotation;
$rotation{'daily'} = "
-rmdir daily.6
-rename daily.5 daily.6
-rename daily.4 daily.5
-rename daily.3 daily.4
-rename daily.2 daily.3
-rename daily.1 daily.2
-rename daily.0 daily.1
";

$rotation{'monthly'} = "
-rmdir monthly.5
-rename monthly.4 monthly.5
-rename monthly.3 monthly.4
-rename monthly.2 monthly.3
-rename monthly.1 monthly.2
-rename monthly.0 monthly.1
-rename weekly.3 monthly.0
";

$rotation{'weekly'} = "
-rmdir weekly.3
-rename weekly.2 weekly.3
-rename weekly.1 weekly.2
-rename weekly.0 weekly.1
-rename daily.6 weekly.0
";

#
# Check which action was called and execute it.
#
my $action = $ARGV[0] ? $ARGV[0] : "";
if ($action eq "daily") {
    rotate("daily", 6);
    sync();
} elsif ($action eq "weekly") {
    rotate("weekly", 3);
} elsif ($action eq "monthly") {
    rotate("monthly", 5);
} elsif ($action eq "sync") {
    sync();
} else {
  print "\n";
  print "Invalid argument.\n" if $action ne "";
  print "Use: $0 [daily|weekly|monthly|sync]\n\n";
  exit;
}


# sync()
#
# Runs rsync to update the lowest interval
sub sync {
  my $interval = $lowest_interval;
  system(
    $conf{'rsync_path'},
    '-e', "ssh -oIdentityFile=$conf{'private_key'}",
    '-az', '--delete',
    "--link-dest='../${interval}.1'",
    $conf{'backup_source'},
    "$conf{'backup_dest'}/${interval}.0/"
  );
}

# rotate(interval, oldest_copy)
#
# Rotates directories, removing the oldest one.
# oldest_copy is the one being discarded/removed
sub rotate {
  my $interval = shift;
  my $oldest_copy = shift;

  sync_to_empty($interval, $oldest_copy);
  sftp_rotate($interval);
}

# sync_to_empty(interval, oldest_copy)
#
#Since DreamHost doesn't allow SSH access into the backup server,
#we must find an alternative way to delete a directory.
#We do this by rsync-ing it to an empty dir
sub sync_to_empty {
  my $interval = shift;
  my $oldest_copy = shift;

  mkdir $conf{'emptydir'};
  system(
    $conf{'rsync_path'},
    '-e', "ssh -oIdentityFile=$conf{'private_key'}",
    '-az', '--delete',
    $conf{'emptydir'},
    "$conf{'backup_dest'}/${interval}.${oldest_copy}/"
  );
  rmdir $conf{'emptydir'};
}

# sftp_rotate(interval)
#
#Opens an SFTP connection to the server
#and issues rmdir/rename to rotate
#backup directories
sub sftp_rotate {
  my $interval = shift;
  open(
    my $sftp_handle, "|-", $conf{'sftp_path'},
    (
      "-oIdentityFile=$conf{'private_key'}",
      '-b', '-',
      $conf{'backup_dest'}
    )
  );
  print $sftp_handle $rotation{$interval};
  close $sftp_handle;
}

# get_basedir()
#
# Figures out and returns the full path to the directory where this file lives
sub get_basedir {
  my ($volume,$dir,$filename) = File::Spec->splitpath( File::Spec->rel2abs(__FILE__ ) );
  return $dir;
}
