

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
