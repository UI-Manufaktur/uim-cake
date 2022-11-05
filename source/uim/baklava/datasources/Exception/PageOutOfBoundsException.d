module uim.baklava.datasources\Exception;

import uim.baklava.core.exceptions\CakeException;

/**
 * Exception raised when requested page number does not exist.
 */
class PageOutOfBoundsException : CakeException
{

    protected $_messageTemplate = 'Page number %s could not be found.';
}
