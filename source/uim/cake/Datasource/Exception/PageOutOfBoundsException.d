module uim.baklava.Datasource\Exception;

import uim.baklava.core.Exception\CakeException;

/**
 * Exception raised when requested page number does not exist.
 */
class PageOutOfBoundsException : CakeException
{

    protected $_messageTemplate = 'Page number %s could not be found.';
}
