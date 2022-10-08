module uim.cake.database.Statement;

/**
 * Statement class meant to be used by an Sqlite driver
 *
 * @internal
 */
class SqliteStatement : StatementDecorator
{
    use BufferResultsTrait;


    bool execute(?array myParams = null) {
        if (this._statement instanceof BufferedStatement) {
            this._statement = this._statement.getInnerStatement();
        }

        if (this._bufferResults) {
            this._statement = new BufferedStatement(this._statement, this._driver);
        }

        return this._statement.execute(myParams);
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
            this._statement.queryString &&
            preg_match('/^(?:DELETE|UPDATE|INSERT)/i', this._statement.queryString)
        ) {
            $changes = this._driver.prepare('SELECT CHANGES()');
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
