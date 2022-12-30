/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/module uim.cake.console\Exception;

/**
 * Used when a shell cannot be found.
 */
class MissingShellException : ConsoleException
{
    /**
     * @var string
     */
    protected _messageTemplate = "Shell class for "%s" could not be found."
        . " If you are trying to use a plugin shell, that was loaded via this.addPlugin(),"
        . " you may need to update bin/cake.php to match https://github.com/UIM/app/tree/master/bin/cake.php";
}
