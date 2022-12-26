


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         2.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */

import uim.cake.Collection\Collection;
import uim.cake.Collection\ICollection;

if (!function_exists("collection")) {
    /**
     * Returns a new {@link \Cake\Collection\Collection} object wrapping the passed argument.
     *
     * @param iterable $items The items from which the collection will be built.
     * @return \Cake\Collection\Collection
     */
    function collection(iterable $items): ICollection
    {
        return new Collection($items);
    }

}
