module uim.cake.Datasource\Exception;

import uim.cake.core.Exception\CakeException;

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
