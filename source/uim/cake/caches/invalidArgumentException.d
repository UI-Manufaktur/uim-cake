/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.caches.invalidargumentexception;;

@safe:
import uim.cake;


// Exception raised when cache keys are invalid.
class InvalidArgumentException : UIMException, IInvalidArgument {
}
