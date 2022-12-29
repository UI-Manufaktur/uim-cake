/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.console\Exception;

@safe:
import uim.cake;

/**
 * Exception class for halting errors in console tasks
 *
 * @see uim.cake.Console\Shell::_stop()
 * @see uim.cake.Console\Shell::error()
 * @see uim.cake.Command\BaseCommand::abort()
 */
class StopException : ConsoleException {
}
