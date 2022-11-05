

import uim.baklava.collection\Collection;
import uim.baklava.collection\ICollection;

if (!function_exists('collection')) {
    /**
     * Returns a new {@link \Cake\Collection\Collection} object wrapping the passed argument.
     *
     * @param iterable myItems The items from which the collection will be built.
     * @return \Cake\Collection\Collection
     */
    ICollection collection(iterable myItems)
    {
        return new Collection(myItems);
    }

}
