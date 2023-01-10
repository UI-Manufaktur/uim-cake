module uim.datasources.Paging;

import uim.datasources.IResultSet;

/**
 * This interface describes the methods for paginator instance.
 */
interface PaginatorInterface
{
    /**
     * Handles pagination of datasource records.
     *
     * @param uim.cake.Datasource\IRepository|uim.cake.Datasource\IQuery $object The repository or query
     *   to paginate.
     * @param array $params Request params
     * @param array $settings The settings/configuration used for pagination.
     * @return uim.cake.Datasource\IResultSet Query results
     */
    function paginate(object $object, array $params = null, array $settings = null): IResultSet;

    /**
     * Get paging params after pagination operation.
     */
    array getPagingParams();
}

// phpcs:disable
class_alias(
    "Cake\Datasource\Paging\PaginatorInterface",
    "Cake\Datasource\PaginatorInterface"
);
// phpcs:enable
