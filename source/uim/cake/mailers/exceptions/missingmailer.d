module uim.cake.mailers.exceptions;

import uim.cake.core.exceptions.UIMException;

/**
 * Used when a mailer cannot be found.
 */
class MissingMailerException : UIMException {

    protected _messageTemplate = "Mailer class '%s' could not be found.";
}
