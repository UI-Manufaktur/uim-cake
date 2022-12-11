module uim.cake.datasources;

@safe:
import uim.cake;

/**
 * Describes how a collection of datasource results should look like
 */
interface IResultSet : ICollection, Countable, Serializable
{
}
