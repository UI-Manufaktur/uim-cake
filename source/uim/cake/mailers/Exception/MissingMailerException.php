module uim.cakeiler\Exception;

import uim.cakere.exceptions\CakeException;

/**
 * Used when a mailer cannot be found.
 */
class MissingMailerException : CakeException
{

    protected $_messageTemplate = 'Mailer class "%s" could not be found.';
}
