module uim.cake.Mailer\Exception;

import uim.cake.core.exceptions\CakeException;

/**
 * Used when a mailer cannot be found.
 */
class MissingMailerException : CakeException
{

    protected $_messageTemplate = 'Mailer class "%s" could not be found.';
}
