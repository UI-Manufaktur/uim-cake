module uim.cake.databases.exceptions;

import uim.cake.core.exceptions.CakeException;

/**
 * Class MissingExtensionException
 */
class MissingExtensionException : CakeException
{

    // phpcs:ignore Generic.Files.LineLength
    protected $_messageTemplate = "Database driver %s cannot be used due to a missing PHP extension or unmet dependency. Requested by connection "%s"";
}
