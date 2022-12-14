/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.console\Exception;

/**
 * Exception class for halting errors in console tasks
 *
 * @see \Cake\Console\Shell::_stop()
 * @see \Cake\Console\Shell::error()
 * @see \Cake\Command\BaseCommand::abort()
 */
class StopException : ConsoleException
{
}
