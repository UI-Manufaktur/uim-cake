/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/module uim.cake.console\Exception;

@safe:
import uim.cake;

// Used when a Task cannot be found.
class MissingTaskException : ConsoleException {
    protected string _messageTemplate = "Task class %s could not be found.";
}
