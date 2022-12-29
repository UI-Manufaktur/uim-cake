module uim.cake.datasources;

/**
 * Simplified paginator which avoids potentially expensives queries
 * to get the total count of records.
 *
 * When using a simple paginator you will not be able to generate page numbers.
 * Instead use only the prev/next pagination controls, and handle 404 errors
 * when pagination goes past the available result set.
 */
class SimplePaginator : Paginator
{
  /**
    * Simple pagination does not perform any count query, so this method returns `null`.
    *
    * @param uim.cake.Datasource\IQuery myQuery Query instance.
    * @param array myData Pagination data.
    * @return int|null
    */
  protected Nullable!int getCount(IQuery myQuery, array myData) {
    return null;
  }
}
