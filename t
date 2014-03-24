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
# ee, February 2013

use v5.10.1;

use strict;
use warnings;
use Carp;
use Term::ANSIColor;
use Readonly;
use English qw( -no_match_vars );
use Method::Signatures;

# Globals
my $home       = $ENV{'HOME'};
my $todo_dir   = "$home/Dropbox/Ideas_and_more/todo/";
my $todo_bin   = './todo.sh';
my $backup_dir = "$home/Documents/Backups/todo/";

my $todo_file  = 'todo.txt';
my @files = ('done.txt', 'report.txt', $todo_file);

my $debug = 0;

sub get_now_string {
    my @time_elems = localtime;

    my $year   = $time_elems[5] + 1900;
    my $mon    = $time_elems[4] +    1;
    my $day    = $time_elems[3];
    my $hour   = $time_elems[2];
    my $minute = $time_elems[1];
    my $second = $time_elems[0];

    if ($mon    < 10) { $mon    = "0$mon";    }
    if ($day    < 10) { $day    = "0$day";    }
    if ($hour   < 10) { $hour   = "0$hour";   }
    if ($minute < 10) { $minute = "0$minute"; }
    if ($second < 10) { $second = "0$second"; }

    return "$year.$mon.$day $hour:$minute:$second";
}

sub debug {
    if ($debug) {
        my @debug_messages = @_;
        my $print_message = get_now_string();
        foreach my $elems (@debug_messages) {
            $print_message .= ' ' . $elems;
        }
        if ($print_message !~ /\n$/xms)  {
            $print_message .= "\n";
        }

        croak $print_message;
    }

    return;
}

sub versioned_backup {
    my $git_args = ' commit -a -m \"commit by t\"';
    backup();

    chdir $backup_dir or croak "Could not cd to $backup_dir: $ERRNO";

    my $git_cmd = 'git ' . $git_args;
    system $git_cmd and croak "Could not run git: $ERRNO";

    return;
}

sub backup {

    if (! -d $backup_dir) {
        system "mkdir -p \"$backup_dir\"" and croak "mkdir \"$backup_dir\": $ERRNO $CHILD_ERROR";
    }

    foreach my $file (@files) {
        system "cp $file \"$backup_dir\"" and croak "Backup $file: $ERRNO $CHILD_ERROR";
    }

    return;
}

sub edit {
    system 'vim todo.txt' and croak "Could not edit: $ERRNO $CHILD_ERROR";

    return;
}

sub help {
    print colored("$PROGRAM_NAME [backup|versioning|edit|e|due [<yyyy.mm.dd>]|lsc <context>"
        . "|lsprj <project>|help] or the commands of todo.sh (see t -h)\n", 'blue');

    return;
}

func get_canonical_date($date) {
    my ($year, $month, $day) = split /[.]/xms, $date;

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


sub today {
    my @time_elems = localtime;
    my $year = $time_elems[5] + 1900;
    my $mon = $time_elems[4] + 1;
    my $day = $time_elems[3];

    if ($mon < 10) { $mon = "0$mon"; }
    if ($day < 10) { $day = "0$day"; }

    return "$year.$mon.$day";
}

func print_colored($line) {
    given ($line) {
        when (/^\d*\s*[(]A[)]/xms) { print colored($line, 'yellow') }
        when (/^\d*\s*[(]B[)]/xms) { print colored($line, 'green') }
        when (/^\d*\s*[(]C[)]/xms) { print colored($line, 'blue') }
        when (/^\d*\s*[(]D[)]/xms) { print colored($line, 'cyan') }
        when (/^\d*\s*[(]E[)]/xms) { print colored($line, 'magenta') }
        default { print $line; }
    }
}

func lsdue($date) {
    my $due_date = get_canonical_date($date);

    open my $todo_fh, '<', $todo_file or croak "Could not open $todo_file: $ERRNO";
    my $line_number = 1;
    while (my $line = <$todo_fh>) {
        debug "Checking: $line";
        $line =~ /due:(\d{2,4}[.]\d{1,2}[.]\d{1,2})/xms;
        my $entry_date = $1;
        my $canonical_entry_date = get_canonical_date($entry_date);
        print_colored($line_number . q/ / . $line)  if $canonical_entry_date le $due_date;
        $line_number++;
    }
    close $todo_fh or croak "Closing file $todo_file: $ERRNO";;
}

func lscon($context) {
    ls_conditional('@' . $context);
}

func lsprj($project) {
    ls_conditional('+' . $project);
}

func ls_conditional($condition) {
    open my $TODO, '<', $todo_file or croak "Could not open $todo_file: $ERRNO";
    my $counter = 1;
    while (my $line = <$TODO>) {
        print_colored("$counter $line")     if $line =~ /$condition/ixms;
        $counter++;
    }
    close $TODO and croak("Could not close read-only file $todo_file: $ERRNO");
}


chdir $todo_dir or croak "Could not cd '$todo_dir': $ERRNO\n";

if ($#ARGV >= 0) {
    my $first_cmd = $ARGV[0];
    my $second_cmd = today();
    if ($#ARGV >= 1) {
        $second_cmd = $ARGV[1];
    }

    given ($first_cmd) {
        when (/^backup$/xms)                { backup();           exit; }
        when (/^edit$/xms || /^e$/xms)      { edit();             exit; }
        when (/^vers/xms)                   { versioned_backup(); exit; }
        when (/^due$/xms)                   { lsdue($second_cmd); exit; }
        when (/^lsc$/xms)                   { lscon($second_cmd); exit; }
        when (/^lsprj$/xms)                 { lsprj($second_cmd); exit; }
        when (/^h/xms)                      { help();             exit; }
    }

    exit;
}

# Otherwise call the regular todo.sh
my $cmd = $todo_bin . q/ /;
for my $arg (@ARGV) {
    $cmd .= q/ / . $arg;
}

system "$cmd";

