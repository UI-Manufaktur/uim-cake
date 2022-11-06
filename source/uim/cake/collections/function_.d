/**
 * @copyright     Copyright (c) Ozan Nurettin Süel (https://www.sicherheitsschmiede.de)
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 **/
module uim.cakellectionss.function_;
s
import uim.cakellections\Collection;
import uim.cakellections\ICollection;

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
