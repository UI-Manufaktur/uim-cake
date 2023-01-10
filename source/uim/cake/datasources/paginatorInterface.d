/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.datasources;

// This interface describes the methods for paginator instance.
interface IPaginator {
    /**
     * Handles pagination of datasource records.
     *
     * @param uim.cake.Datasource\IRepository|uim.cake.Datasource\IQuery $object The repository or query
     *   to paginate.
     * @param array myParams Request params
     * @param array $settings The settings/configuration used for pagination.
     * @return uim.cake.Datasource\IResultSet Query results
     */
    function paginate(object $object, array myParams = null, array $settings = null): IResultSet;

    /**
     * Get paging params after pagination operation.
     * @return array
     */
    array getPagingParams();
}
class_exists("Cake\Datasource\Paging\PaginatorInterface");
deprecationWarning(
    "Use Cake\Datasource\Paging\PaginatorInterface instead of Cake\Datasource\PaginatorInterface."
);