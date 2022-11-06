module uim.caketasources\Exception;

import uim.cakere.exceptions\CakeException;

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
