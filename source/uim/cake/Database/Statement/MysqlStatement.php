


 *



  */
module uim.cake.databases.Statement;

use PDO;

/**
 * Statement class meant to be used by a MySQL PDO driver
 *
 * @internal
 */
class MysqlStatement : PDOStatement
{
    use BufferResultsTrait;


    function execute(?array $params = null): bool
    {
        $connection = _driver.getConnection();

        try {
            $connection.setAttribute(PDO::MYSQL_ATTR_USE_BUFFERED_QUERY, _bufferResults);
            $result = _statement.execute($params);
        } finally {
            $connection.setAttribute(PDO::MYSQL_ATTR_USE_BUFFERED_QUERY, true);
        }

        return $result;
    }
}
