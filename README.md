t
=

Wrapper and Frontend around todo.sh
----------------------

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

Any other command is passed through to "todo.sh"
