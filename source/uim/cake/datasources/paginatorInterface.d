module uim.cake.datasources;

/**
 * This interface describes the methods for paginator instance.
 */
interface PaginatorInterface
{
    /**
     * Handles pagination of datasource records.
     *
     * @param \Cake\Datasource\IRepository|\Cake\Datasource\QueryInterface $object The repository or query
     *   to paginate.
     * @param array myParams Request params
     * @param array $settings The settings/configuration used for pagination.
     * @return \Cake\Datasource\ResultSetInterface Query results
     */
    function paginate(object $object, array myParams = [], array $settings = []): ResultSetInterface;

    /**
     * Get paging params after pagination operation.
     *
     * @return array
     */
    auto getPagingParams(): array;
}
