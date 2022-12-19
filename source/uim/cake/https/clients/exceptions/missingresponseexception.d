module uim.cake.https.clients\Exception;

import uim.cake.core.exceptions\CakeException;

/**
 * Used to indicate that a request did not have a matching mock response.
 */
class MissingResponseException : CakeException
{
    /**
     * @var string
     */
    protected _messageTemplate = "Unable to find a mocked response for `%s` to `%s`.";
}
