

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
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
namespace Cake\Database\Statement;

/**
 * Statement class meant to be used by an Sqlite driver
 *
 * @internal
 */
class SqliteStatement : StatementDecorator
{
    use BufferResultsTrait;

    /**
     * @inheritDoc
     */
    function execute(?array $params = null): bool
    {
        if (_statement instanceof BufferedStatement) {
            _statement = _statement.getInnerStatement();
        }

        if (_bufferResults) {
            _statement = new BufferedStatement(_statement, _driver);
        }

        return _statement.execute($params);
    }

    /**
     * Returns the number of rows returned of affected by last execution
     *
     * @return int
     */
    function rowCount(): int
    {
        /** @psalm-suppress NoInterfaceProperties */
        if (
            _statement.queryString &&
            preg_match('/^(?:DELETE|UPDATE|INSERT)/i', _statement.queryString)
        ) {
            $changes = _driver.prepare('SELECT CHANGES()');
            $changes.execute();
            $row = $changes.fetch();
            $changes.closeCursor();

            if (!$row) {
                return 0;
            }

            return (int)$row[0];
        }

        return parent::rowCount();
    }
}
