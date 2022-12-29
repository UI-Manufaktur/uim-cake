


 *


 * @since         3.0.0
  */
module uim.cake.Datasource;

import uim.cake.Collection\ICollection;
use Countable;
use Serializable;

/**
 * Describes how a collection of datasource results should look like
 */
interface IResultSet : ICollection, Countable, Serializable
{
}
