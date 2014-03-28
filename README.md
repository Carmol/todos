todo.pl - A Wrapper and Frontend around todo.sh
================

Calls todo.sh where it is installed ($TODO_DIR).
t can be installed in the path; it chdirs to $TODO_DIR and calls
todo.sh there.

The following commands/arguments are added to the classical
todo.sh:
 
  * backup   
 If the command backup is given (e.g., "t backup"), t backups the  three files done.txt, report.txt and todo.txt to $BACKUP_DIR.

  * versioning   
 Uses git to do a versioned backup; no message entry possible, yet.
 
  * edit   
 Starts editing todo.txt in vim

  * vers   
 Creates git based "versioned" backup

  * due <date>   
 Lists all tasks are due since/by date or by today, if data is omitted

  * lsc <context>   
 Lists all tasks of a particular context

  * lsprj <project>   
 Lists all tasks of a particular project

  * help   
 Prints a (very brief) help line

Any other command is passed through to "todo.sh"

Open 
----
Combine various commands, e.g., todo.pl due <date> lsc <context> lsprj <project>
