/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.Mailer;

import uim.cake.core.exceptions.UIMException;
import uim.cake.core.InstanceConfigTrait;

/**
 * Abstract transport for sending email
 */
abstract class AbstractTransport
{
    use InstanceConfigTrait;

    /**
     * Default config for this class
     *
     * @var array<string, mixed>
     */
    protected _defaultConfig = null;

    /**
     * Send mail
     *
     * @param uim.cake.mailers.Message $message Email message.
     * @return array

     */
    abstract array send(Message $message);

    /**
     * Constructor
     *
     * @param array<string, mixed> aConfig Configuration options.
     */
    this(Json aConfig = null) {
        this.setConfig(aConfig);
    }

    /**
     * Check that at least one destination header is set.
     *
     * @param uim.cake.mailers.Message $message Message instance.
     * @return void
     * @throws uim.cake.Core\exceptions.UIMException If at least one of to, cc or bcc is not specified.
     */
    protected void checkRecipient(Message $message) {
        if (
            $message.getTo() == null
            && $message.getCc() == null
            && $message.getBcc() == null
        ) {
            throw new UIMException(
                "You must specify at least one recipient."
                ~ " Use one of `setTo`, `setCc` or `setBcc` to define a recipient."
            );
        }
    }
}
