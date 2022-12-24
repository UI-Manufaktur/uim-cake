

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.5.0
 * @license       https://www.opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Datasource\Paging;

import uim.cake.Datasource\IResultSet;

/**
 * This interface describes the methods for paginator instance.
 */
interface PaginatorInterface
{
    /**
     * Handles pagination of datasource records.
     *
     * @param \Cake\Datasource\RepositoryInterface|\Cake\Datasource\IQuery $object The repository or query
     *   to paginate.
     * @param array $params Request params
     * @param array $settings The settings/configuration used for pagination.
     * @return \Cake\Datasource\IResultSet Query results
     */
    function paginate(object $object, array $params = [], array $settings = []): IResultSet;

    /**
     * Get paging params after pagination operation.
     *
     * @return array
     */
    function getPagingParams(): array;
}

// phpcs:disable
class_alias(
    "Cake\Datasource\Paging\PaginatorInterface",
    "Cake\Datasource\PaginatorInterface"
);
// phpcs:enable
