module uim.cake.Mailer\Exception;

import uim.cake.core.exceptions.CakeException;

/**
 * Missing Action exception - used when a mailer action cannot be found.
 */
class MissingActionException : CakeException
{

    protected $_messageTemplate = "Mail %s::%s() could not be found, or is not accessible.";
}
