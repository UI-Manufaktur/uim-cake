/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/module uim.cake.orm.Exception;

import uim.cake.core.exceptions\UIMException;

/**
 * Exception raised when an Entity could not be found.
 */
class MissingEntityException : UIMException {
    /**
     * @var string
     */
    protected _messageTemplate = "Entity class %s could not be found.";
}
