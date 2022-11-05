module uim.baklava.datasources\Exception;

import uim.baklava.core.exceptions\CakeException;

/**
 * Used when a model cannot be found.
 */
class MissingModelException : CakeException
{
    /**
     * @var string
     */
    protected $_messageTemplate = 'Model class "%s" of type "%s" could not be found.';
}
