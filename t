#!/usr/bin/perl
#
# t         Wrapper around todo.sh
#
# Calls todo.sh where it is installed ($todo_dir).
# t can be installed in the path; it chdirs to $todo_dir and calls
# todo.sh there.
#
# The following commands/arguments are added to the classical
# todo.sh:
# 
# backup
#   If the command backup is given (e.g., "t backup"), t backups the
#   three files done.txt, report.txt and todo.txt to $backup_dir.
#
# versioning
#   Uses git to do a versioned backup; no message entry possible, yet.
# 
# edit
#   Starts editing todo.txt in vim
#
# Any other command is given to "todo.sh"
#
# ********** Open Items / Todos *************
# Instead of one shot backups, use versioning (Git)
#
#
#
#
# Emmerich Eggler, February 2013

use strict;
use warnings;
#use TERM::ANSIColor qw(:constants);
use Term::ANSIColor;

# Globals
my $home = $ENV{'HOME'};
my $todo_dir="$home/Dropbox/Ideas_and_more/todo/";
my $todo_bin="./todo.sh";
my $backup_dir="$home/Documents/Backups/todo/";

my $todo_file = "todo.txt";
my @files = ("done.txt", "report.txt", $todo_file);

my $debug = 0;

sub get_now_string() {
    my @time_elems = localtime();

    my $year = $time_elems[5] + 1900;
    my $mon = $time_elems[4] + 1;
    my $day = $time_elems[3];
    my $hour = $time_elems[2];
    my $minute = $time_elems[1];
    my $second = $time_elems[0];

    if ($mon < 10) { $mon = "0$mon"; }
    if ($day < 10) { $day = "0$day"; }
    if ($hour < 10) { $hour = "0$hour"; }
    if ($minute < 10) { $minute = "0$minute"; }
    if ($second < 10) { $second = "0$second"; }

    return "$year.$mon.$day $hour:$minute:$second";
}

sub debug {
    if ($debug) {
        my @debug_messages = @_;
        my $print_message = get_now_string();
        foreach my $elems (@debug_messages) {
            $print_message .= " " . $elems;
        }
        if ($print_message !~ /\n$/)  {
            $print_message .= "\n";
        }

        warn $print_message;
    }
}

sub versioned_backup() {
    my $git_args = " commit -a -m \"commit by t\"";
    backup();

    chdir($backup_dir) or die "Could not cd to $backup_dir: $!";

    # do the git stuff on the interesting files:
    my $git_cmd = "git ";
    $git_cmd .= $git_args;

    system($git_cmd) and die "Could not run git: $!";
}

sub backup() {

    unless ( -d $backup_dir) {
        system("mkdir -p \"$backup_dir\"") and die "mkdir \"$backup_dir\": $! $?";
    }

    foreach my $file (@files) {
        system("cp $file \"$backup_dir\"") and die "Backup $file: $! $?";
    }
}

sub edit() {
    system("vim todo.txt") and die "Could not edit: $! $?";
}

sub help() {
    print colored("$0 [backup|versioning|edit|e|due [<yyyy.mm.dd>]|lsc <context>"
      . "|lsprj <project>|help] or the commands of todo.sh (see t -h)\n", "blue");
}

sub get_canonical_date($) {
    my $date = shift();

    my ($year, $month, $day) = split(/\./, $date);

    if (length($year ) == 2) {
        $year = 2000 + $year;
    }
    if (length($month) == 1) {
        $month = 10 + $month;
    }
    if (length($day) == 1) {
        $day = 10 + $day;
    }
    my $ret_val = "$year.$month.$day";

    debug "get_canonical_date - returning: $ret_val";

    return $ret_val;
}


sub today() {
    my @time_elems = localtime();
    my $year = $time_elems[5] + 1900;
    my $mon = $time_elems[4] + 1;
    my $day = $time_elems[3];

    if ($mon < 10) { $mon = "0$mon"; }
    if ($day < 10) { $day = "0$day"; }

    return "$year.$mon.$day";
}

sub print_colored($) {
    my $line = shift();

    if ($line =~ /^[0-9]*\s*\(A\)/) { print colored($line, 'yellow'); }
    elsif ($line =~ /^[0-9]*\s*\(B\)/) { print colored($line, 'green'); }
    elsif ($line =~ /^[0-9]*\s*\(C\)/) { print colored($line, 'blue'); }
    elsif ($line =~ /^[0-9]*\s*\(D\)/) { print colored($line, 'cyan'); }
    elsif ($line =~ /^[0-9]*\s*\(E\)/) { print colored($line, 'magenta'); }
    else { print $line; }
}

sub lsdue {
    my $due_date = get_canonical_date(shift());

    open(TODO, $todo_file)
        or die "Could not open $todo_file: $!";
    my $line_number = 1;
    foreach my $line (<TODO>) {
        debug "Checking: $line";
        if ($line !~ /due:([0-9]{2,4}\.[0-9]{1,2}\.[0-9]{1,2})/) {
            debug "Didn't find due date\n";
        }
		else {
        	my $entry_date = $1;
        	my $canonical_entry_date = get_canonical_date($entry_date);
        	if ($canonical_entry_date le $due_date) {
            	print_colored($line_number . " " . $line);
        	}
		}	
		$line_number++;

    }
    close(TODO);
}

sub lscon($) {
    my $context = shift();

    ls_conditional("\\@" . $context);
}

sub lsprj($) {
    my $project = shift();

    ls_conditional("\\+$project");
    exit;
}

sub ls_conditional($) {
    my $condition = shift();

    open(TODO, $todo_file)
        or die "Could not open $todo_file: $!";
    my $counter = 1;
    foreach my $line (<TODO>) {
        if ($line =~ /$condition/i) {
            print_colored($counter . " " . $line);
        }
        $counter++;
    }
}


chdir($todo_dir) or die "Could not cd '$todo_dir': $! $?\n";

if ($#ARGV >= 0) {
  my $first_cmd = $ARGV[0];
  if ($first_cmd eq "backup") {
    backup();
    exit;
  }
  if ($first_cmd eq "edit" || $first_cmd eq "e") {
    edit();
    exit;
  }
  if ($first_cmd =~ /^vers/i) {
    versioned_backup();
    exit;
  }
  if ($first_cmd eq "due") {
     if ($#ARGV >= 1) {
        my $second_cmd = $ARGV[1];
        lsdue($second_cmd);
      }
      else {
        lsdue(today());
      }
      exit;
  }
  if ($first_cmd eq "lsc" and $#ARGV >= 1) {
    my $second_cmd = $ARGV[1];
    lscon($second_cmd);
    exit;
  }
  if ($first_cmd eq "lsprj" and $#ARGV >= 1) {
    my $second_cmd = $ARGV[1];
    lsprj($second_cmd);
    exit;
  }
  if ($first_cmd eq "help") {
    help();
    exit;
  }
}

my $cmd = "$todo_bin ";
for (my $i = 0; $i <= $#ARGV; $i++) {
  $cmd .= " " . $ARGV[$i];
}
system("$cmd");

