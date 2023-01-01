

import uim.cake.Collection\Collection;
import uim.cake.Collection\ICollection;

if (!function_exists("collection")) {
    /**
     * Returns a new {@link uim.cake.Collection\Collection} object wrapping the passed argument.
     *
     * @param iterable $items The items from which the collection will be built.
     * @return uim.cake.Collection\Collection
     */
    function collection(iterable $items): ICollection
    {
        return new Collection($items);
    }

}