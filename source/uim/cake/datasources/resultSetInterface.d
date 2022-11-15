module uim.cake.datasources;

import uim.cake.collections\ICollection;
use Countable;
use Serializable;

/**
 * Describes how a collection of datasource results should look like
 */
interface ResultSetInterface : ICollection, Countable, Serializable
{
}
