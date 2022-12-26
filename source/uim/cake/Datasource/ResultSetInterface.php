


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
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
