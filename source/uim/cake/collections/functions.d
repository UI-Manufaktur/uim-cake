/*********************************************************************************************************
  Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
  License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
  Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.collections.functions;

import uim.cake.collections.Collection;
import uim.cake.collections.ICollection;

if (!function_exists("collection")) {
    /**
     * Returns a new {@link uim.cake.collections.Collection} object wrapping the passed argument.
     *
     * @param iterable $items The items from which the collection will be built.
     * @return uim.cake.collections.Collection
     */
    function collection(iterable $items): ICollection
    {
        return new Collection($items);
    }

}
