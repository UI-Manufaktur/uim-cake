module uim.cake.databases.Statement;

/**
 * Statement class meant to be used by an Sqlite driver
 *
 * @internal
 */
class SqliteStatement : StatementDecorator
{
    use BufferResultsTrait;


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
     */
    int rowCount(): int
    {
        /** @psalm-suppress NoInterfaceProperties */
        if (
            _statement.queryString &&
            preg_match("/^(?:DELETE|UPDATE|INSERT)/i", _statement.queryString)
        ) {
            $changes = _driver.prepare("SELECT CHANGES()");
            $changes.execute();
            $row = $changes.fetch();
            $changes.closeCursor();

            if (!$row) {
                return 0;
            }

            return (int)$row[0];
        }

        return super.rowCount();
    }
}