module uim.baklava.databases.exceptions;

import uim.baklava.core.Exception\CakeException;

/**
 * Class MissingExtensionException
 */
class MissingExtensionException : CakeException
{

    // phpcs:ignore Generic.Files.LineLength
    protected $_messageTemplate = 'Database driver %s cannot be used due to a missing PHP extension or unmet dependency';
}
