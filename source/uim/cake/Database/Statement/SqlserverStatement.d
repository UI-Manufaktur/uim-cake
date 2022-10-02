module uim.cake.database.Statement;

use PDO;

/**
 * Statement class meant to be used by an Sqlserver driver
 *
 * @internal
 */
class SqlserverStatement : PDOStatement
{
    /**
     * {@inheritDoc}
     *
     * The SQL Server PDO driver requires that binary parameters be bound with the SQLSRV_ENCODING_BINARY attribute.
     * This overrides the PDOStatement::bindValue method in order to bind binary columns using the required attribute.
     *
     * @param string|int $column name or param position to be bound
     * @param mixed myValue The value to bind to variable in query
     * @param string|int|null myType PDO type or name of configured Type class
     * @return void
     */
    function bindValue($column, myValue, myType = 'string'): void
    {
        if (myType === null) {
            myType = 'string';
        }
        if (!is_int(myType)) {
            [myValue, myType] = this.cast(myValue, myType);
        }
        if (myType === PDO::PARAM_LOB) {
            /** @psalm-suppress UndefinedConstant */
            this._statement.bindParam($column, myValue, myType, 0, PDO::SQLSRV_ENCODING_BINARY);
        } else {
            this._statement.bindValue($column, myValue, myType);
        }
    }
}
