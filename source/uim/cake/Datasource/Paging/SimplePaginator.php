


 *


 * @since         3.9.0
 * @license       https://www.opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Datasource\Paging;

import uim.cake.Datasource\IQuery;

/**
 * Simplified paginator which avoids potentially expensives queries
 * to get the total count of records.
 *
 * When using a simple paginator you will not be able to generate page numbers.
 * Instead use only the prev/next pagination controls, and handle 404 errors
 * when pagination goes past the available result set.
 */
class SimplePaginator : NumericPaginator
{
    /**
     * Simple pagination does not perform any count query, so this method returns `null`.
     *
     * @param \Cake\Datasource\IQuery $query Query instance.
     * @param array $data Pagination data.
     * @return int|null
     */
    protected function getCount(IQuery $query, array $data): ?int
    {
        return null;
    }
}

// phpcs:disable
class_alias(
    "Cake\Datasource\Paging\SimplePaginator",
    "Cake\Datasource\SimplePaginator"
);
// phpcs:enable
