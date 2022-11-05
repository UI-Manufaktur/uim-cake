module uim.baklava.https\Client\Exception;

import uim.baklava.core.exceptions\CakeException;

/**
 * Used to indicate that a request did not have a matching mock response.
 */
class MissingResponseException : CakeException
{
    /**
     * @var string
     */
    protected $_messageTemplate = 'Unable to find a mocked response for `%s` to `%s`.';
}
