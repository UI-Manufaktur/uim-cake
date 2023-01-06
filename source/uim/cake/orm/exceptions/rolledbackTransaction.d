/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/module uim.cake.orm.Exception;

import uim.cake.core.exceptions\CakeException;

/**
 * Used when a transaction was rolled back from a callback event.
 */
class RolledbackTransactionException : CakeException {
    /**
     * @var string
     */
    protected _messageTemplate = "The afterSave event in "%s" is aborting the transaction"
        ~ " before the save process is done.";
}
