module uim.baklava.Datasource;

import uim.baklava.collection\ICollection;
use Countable;
use Serializable;

/**
 * Describes how a collection of datasource results should look like
 */
interface ResultSetInterface : ICollection, Countable, Serializable
{
}
