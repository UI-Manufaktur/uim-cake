module uim.cake.datasources.Paging;

import uim.cake.datasources.IResultSet;

/**
 * This interface describes the methods for paginator instance.
 */
interface PaginatorInterface
{
    /**
     * Handles pagination of datasource records.
     *
     * @param uim.cake.Datasource\RepositoryInterface|uim.cake.Datasource\IQuery $object The repository or query
     *   to paginate.
     * @param array $params Request params
     * @param array $settings The settings/configuration used for pagination.
     * @return uim.cake.Datasource\IResultSet Query results
     */
    function paginate(object $object, array $params = [], array $settings = []): IResultSet;

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
