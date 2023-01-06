module uim.cake.datasources;

@safe:
import uim.cake;

import uim.cake.collections.ICollection;
use Countable;
use Serializable;

/**
 * Describes how a collection of datasource results should look like
 */
interface IResultSet : ICollection, Countable, Serializable
{
}