#!/usr/bin/env perl
#
# todo.pl         Wrapper around todo.sh
#
# Calls todo.sh where it is installed ($TODO_DIR).
# t can be installed in the path; it chdirs to $TODO_DIR and calls
# todo.sh there.
#
# The following commands/arguments are added to the classical
# todo.sh:
#
# backup
#   If the command backup is given (e.g., "t backup"), t backups the
#   three files done.txt, report.txt and todo.txt to $BACKUP_DIR.
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
# ee, March and April 2014

use v5.0014;

use strict;
use warnings;
use Carp;
use Term::ANSIColor;
use Readonly;
use English qw( -no_match_vars );
use Method::Signatures;

no if $PERL_VERSION >= 5.018, warnings => "experimental";

# Globals
Readonly my $HOME           => $ENV{'HOME'};
Readonly my $TODO_DIR       => "$HOME/Dropbox/Ideas_and_more/todo/";
Readonly my $TODO_BIN       => './todo.sh';
Readonly my $BACKUP_DIR     => "$HOME/Documents/Backups/todo/";
Readonly my $TODO_FILE      => 'todo.txt';
Readonly my @FILES          => ( 'done.txt', 'report.txt', $TODO_FILE );
Readonly my $GIT_CMD        => 'git';
Readonly my @GIT_ARGS       => qw(commit -a -m "commit by t");
Readonly my @MKDIR_CMD_ARGS => qw(mkdir -p "$BACKUP_DIR");
Readonly my $COPY_CMD       => q(cp);
Readonly my @EDIT_CMD       => qq(vim $TODO_FILE);

sub get_now_string {
    my @time_elems = localtime;

    my $year   = $time_elems[5] + 1900;
    my $mon    = $time_elems[4] + 1;
    my $day    = $time_elems[3];
    my $hour   = $time_elems[2];
    my $minute = $time_elems[1];
    my $second = $time_elems[0];

    if ( $mon < 10 )    { $mon    = "0$mon"; }
    if ( $day < 10 )    { $day    = "0$day"; }
    if ( $hour < 10 )   { $hour   = "0$hour"; }
    if ( $minute < 10 ) { $minute = "0$minute"; }
    if ( $second < 10 ) { $second = "0$second"; }

    return "$year.$mon.$day $hour:$minute:$second";
}

sub today {
    my @time_elems = localtime;
    my $year       = $time_elems[5] + 1900;
    my $mon        = $time_elems[4] + 1;
    my $day        = $time_elems[3];

    if ( $mon < 10 ) { $mon = "0$mon"; }
    if ( $day < 10 ) { $day = "0$day"; }

    return "$year.$mon.$day";
}

sub versioned_backup {
    backup();
    chdir $BACKUP_DIR or croak "Could not cd to $BACKUP_DIR: $ERRNO";
    system $GIT_CMD, @GIT_ARGS and croak "Could not run $GIT_CMD: $ERRNO";
}

sub backup {
    if ( !-d $BACKUP_DIR ) {
        system @MKDIR_CMD_ARGS
            and croak "mkdir '$BACKUP_DIR': $ERRNO $CHILD_ERROR";
    }

    foreach my $file (@FILES) {
        system $COPY_CMD, $file, $BACKUP_DIR
            and croak "Backup $file: $ERRNO $CHILD_ERROR";
    }
}

sub edit {
    system @EDIT_CMD and croak "Could not edit: $ERRNO $CHILD_ERROR";
}

sub help {
    print colored(
            "$PROGRAM_NAME "
            . '[backup|versioning|edit|e|due [<yyyy.mm.dd>]|lsc <context>'
            . '|lsprj <project>|help] or the commands of todo.sh '
            . "(see t -h)\n",
            'blue'
            );
}

func get_canonical_date($date) {
    my ($year, $month, $day) = split q/./, $date;

    if (!defined $year or length $year == 0) {
        return today();
    }

    if (length($year) <= 2) { $year = 2000 + $year; } 
    if (length($month) == 1) { $month = "0$month"; }
    if (length($day) == 1)   { $day   = "0$day"; }

    return "$year.$month.$day";
}

func print_colored($line) {
    given ($line)
    {
        when (/^\d*\s*[(]A[)]/xms) { print colored( $line, 'yellow' ) }
        when (/^\d*\s*[(]B[)]/xms) { print colored( $line, 'green' ) }
        when (/^\d*\s*[(]C[)]/xms) { print colored( $line, 'blue' ) }
        when (/^\d*\s*[(]D[)]/xms) { print colored( $line, 'cyan' ) }
        when (/^\d*\s*[(]E[)]/xms) { print colored( $line, 'magenta' ) }
        default                    { print $line; }
    }
}

func lsdue($date) {
    my $due_date = get_canonical_date($date);

    my $line_number = 1;
    open my $todo_fh, '<', $TODO_FILE
        or croak "Could not open $TODO_FILE: $ERRNO";
    while (my $line = <$todo_fh>) {
        if ($line =~ /due:(\d{2,4}[.]\d{1,2}[.]\d{1,2})/xms) {
            my $canonical_entry_date = get_canonical_date($1);
            if ($canonical_entry_date le $due_date) {
                print_colored($line_number . q/ / . $line);
            }
        }
        $line_number++;
    }
    close $todo_fh or croak "Closing file $TODO_FILE: $ERRNO";
}

func ls_conditional($condition) {
    open my $TODO, '<', $TODO_FILE
        or croak "Could not open $TODO_FILE: $ERRNO";
    my $counter = 1;
    while (my $line = <$TODO>) {
        print_colored("$counter $line") if $line =~ /$condition/ixms;
        $counter++;
    }
    close $TODO
        and croak("Could not close read-only file $TODO_FILE: $ERRNO");
}

# Start of the program
chdir $TODO_DIR or croak "Could not cd '$TODO_DIR': $ERRNO\n";

if ($#ARGV >= 0) {
    my $first_arg  = $ARGV[0];
    my $second_arg = (defined $ARGV[1] ? $ARGV[1] : today());

    given ($first_arg) {
        when (/^backup$/xms) { backup(); exit; }
        when ( /^edit$/xms || /^e$/xms ) { edit(); exit; }
        when (/^vers/xms)   { versioned_backup();                  exit; }
        when (/^due$/xms)   { lsdue($second_arg);                  exit; }
        when (/^lsc$/xms)   { ls_conditional( '@' + $second_arg ); exit; }
        when (/^lsprj$/xms) { ls_conditional( '+' . $second_arg ); exit; }
        when (/^h/xms)      { help();                              exit; }
    }
}

# Otherwise call the regular todo.sh
# Is this too dangerous, to just pass the command line args to todo.sh?
# I'm not sure. Since this is direct user input, any user could directly
# destroy his or her todo.txt or whatever directly with the more ease...
system $TODO_BIN, @ARGV;

