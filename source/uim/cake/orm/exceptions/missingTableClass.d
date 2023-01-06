/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/module uim.cake.orm.Exception;

import uim.cake.core.exceptions\CakeException;

/**
 * Exception raised when a Table could not be found.
 */
class MissingTableClassException : CakeException {
    /**
     * @var string
     */
    protected _messageTemplate = "Table class %s could not be found.";
}
