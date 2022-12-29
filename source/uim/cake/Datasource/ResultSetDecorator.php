


 *


 * @since         3.0.0
  */
module uim.cake.Datasource;

import uim.cake.Collection\Collection;
use Countable;

/**
 * Generic ResultSet decorator. This will make any traversable object appear to
 * be a database result
 */
class ResultSetDecorator : Collection : IResultSet
{
    /**
     * Make this object countable.
     *
     * Part of the Countable interface. Calling this method
     * will convert the underlying traversable object into an array and
     * get the count of the underlying data.
     *
     * @return int
     */
    function count(): int
    {
        $iterator = this.getInnerIterator();
        if ($iterator instanceof Countable) {
            return $iterator.count();
        }

        return count(this.toArray());
    }
}
