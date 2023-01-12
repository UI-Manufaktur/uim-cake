/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/module uim.cake.viewss.exceptions;

@safe:
import uim.cake;

/**
 * Used when a helper cannot be found.
 */
class MissingHelperException : UIMException {
    
    protected _messageTemplate = "Helper class %s could not be found.";
}
