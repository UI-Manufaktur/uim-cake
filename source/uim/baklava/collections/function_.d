/**
 * @copyright     Copyright (c) Ozan Nurettin Süel (https://www.sicherheitsschmiede.de)
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 **/
module uim.baklava.collectionss.function_;
s
import uim.baklava.collections\Collection;
import uim.baklava.collections\ICollection;

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
