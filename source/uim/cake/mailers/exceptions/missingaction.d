module uim.cake.mailers.exceptions;

import uim.cake.core.exceptions.UIMException;

/**
 * Missing Action exception - used when a mailer action cannot be found.
 */
class MissingActionException : UIMException {

    protected _messageTemplate = "Mail %s::%s() could not be found, or is not accessible.";
}
