module uim.baklava.datasources;

import uim.baklava.collections\ICollection;
use Countable;
use Serializable;

/**
 * Describes how a collection of datasource results should look like
 */
interface ResultSetInterface : ICollection, Countable, Serializable
{
}
