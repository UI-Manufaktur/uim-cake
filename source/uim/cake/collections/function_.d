module uim.cake.collections.function_;

@safe:
import uim.cake;

if (!function_exists("collection")) {
    /**
     * Returns a new {@link \Cake\Collection\Collection} object wrapping the passed argument.
     *
     * @param iterable myItems The items from which the collection will be built.
     * @return uim.cake.Collection\Collection
     */
    ICollection collection(iterable myItems) {
        return new Collection(myItems);
    }

}
