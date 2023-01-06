/*********************************************************************************************************
  Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
  License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
  Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.databases.Type;

/**
 * An interface used by Type objects to signal whether the casting
 * is actually required.
 */
interface OptionalConvertInterface
{
    /**
     * Returns whether the cast to PHP is required to be invoked, since
     * it is not a identity function.
     */
    bool requiresToPhpCast();
}
