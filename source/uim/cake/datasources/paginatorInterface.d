module uim.cake.datasources;

// This interface describes the methods for paginator instance.
interface IPaginator {
    /**
     * Handles pagination of datasource records.
     *
     * @param uim.cake.Datasource\IRepository|\Cake\Datasource\IQuery $object The repository or query
     *   to paginate.
     * @param array myParams Request params
     * @param array $settings The settings/configuration used for pagination.
     * @return \Cake\Datasource\IResultSet Query results
     */
    function paginate(object $object, array myParams = [], array $settings = []): IResultSet;

    /**
     * Get paging params after pagination operation.
     * @return array
     */
    auto getPagingParams(): array;
}
