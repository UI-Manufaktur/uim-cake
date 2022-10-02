module uim.cake.database.Exception;

import uim.cake.core.Exception\CakeException;

/**
 * Class MissingDriverException
 */
class MissingDriverException : CakeException
{
    /**
     * @inheritDoc
     */
    protected $_messageTemplate = 'Database driver %s could not be found.';
}
