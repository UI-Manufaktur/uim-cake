module uim.cake.database.Statement;

use PDO;

/**
 * Statement class meant to be used by a MySQL PDO driver
 *
 * @internal
 */
class MysqlStatement : PDOStatement
{
    use BufferResultsTrait;


    bool execute(?array myParams = null) {
        myConnection = this._driver.getConnection();

        try {
            myConnection.setAttribute(PDO::MYSQL_ATTR_USE_BUFFERED_QUERY, this._bufferResults);
            myResult = this._statement.execute(myParams);
        } finally {
            myConnection.setAttribute(PDO::MYSQL_ATTR_USE_BUFFERED_QUERY, true);
        }

        return myResult;
    }
}
