module uim.cake.databases.Driver;

import uim.cake.databases.Expression\ComparisonExpression;
import uim.cake.databases.Expression\IdentifierExpression;
import uim.cake.databases.IdentifierQuoter;
import uim.cake.databases.Query;
use Closure;
use RuntimeException;

/**
 * Sql dialect trait
 *
 * @internal
 */
trait SqlDialectTrait
{
    /**
     * Quotes a database identifier (a column name, table name, etc..) to
     * be used safely in queries without the risk of using reserved words
     *
     * @param string myIdentifier The identifier to quote.
     * @return string
     */
    string quoteIdentifier(string myIdentifier)
    {
        myIdentifier = trim(myIdentifier);

        if (myIdentifier === '*' || myIdentifier === '') {
            return myIdentifier;
        }

        // string
        if (preg_match('/^[\w-]+$/u', myIdentifier)) {
            return this._startQuote . myIdentifier . this._endQuote;
        }

        // string.string
        if (preg_match('/^[\w-]+\.[^ \*]*$/u', myIdentifier)) {
            myItems = explode('.', myIdentifier);

            return this._startQuote . implode(this._endQuote . '.' . this._startQuote, myItems) . this._endQuote;
        }

        // string.*
        if (preg_match('/^[\w-]+\.\*$/u', myIdentifier)) {
            return this._startQuote . str_replace('.*', this._endQuote . '.*', myIdentifier);
        }

        // Functions
        if (preg_match('/^([\w-]+)\((.*)\)$/', myIdentifier, $matches)) {
            return $matches[1] . '(' . this.quoteIdentifier($matches[2]) . ')';
        }

        // Alias.field AS thing
        if (preg_match('/^([\w-]+(\.[\w\s-]+|\(.*\))*)\s+AS\s*([\w-]+)$/ui', myIdentifier, $matches)) {
            return this.quoteIdentifier($matches[1]) . ' AS ' . this.quoteIdentifier($matches[3]);
        }

        // string.string with spaces
        if (preg_match('/^([\w-]+\.[\w][\w\s\-]*[\w])(.*)/u', myIdentifier, $matches)) {
            myItems = explode('.', $matches[1]);
            myField = implode(this._endQuote . '.' . this._startQuote, myItems);

            return this._startQuote . myField . this._endQuote . $matches[2];
        }

        if (preg_match('/^[\w_\s-]*[\w_-]+/u', myIdentifier)) {
            return this._startQuote . myIdentifier . this._endQuote;
        }

        return myIdentifier;
    }

    /**
     * Returns a callable function that will be used to transform a passed Query object.
     * This function, in turn, will return an instance of a Query object that has been
     * transformed to accommodate any specificities of the SQL dialect in use.
     *
     * @param string myType the type of query to be transformed
     * (select, insert, update, delete)
     * @return \Closure
     */
    function queryTranslator(string myType): Closure
    {
        return function (myQuery) use (myType) {
            if (this.isAutoQuotingEnabled()) {
                myQuery = (new IdentifierQuoter(this)).quote(myQuery);
            }

            /** @var \Cake\ORM\Query myQuery */
            myQuery = this.{'_' . myType . 'QueryTranslator'}(myQuery);
            $translators = this._expressionTranslators();
            if (!$translators) {
                return myQuery;
            }

            myQuery.traverseExpressions(function ($expression) use ($translators, myQuery): void {
                foreach ($translators as myClass => $method) {
                    if ($expression instanceof myClass) {
                        this.{$method}($expression, myQuery);
                    }
                }
            });

            return myQuery;
        };
    }

    /**
     * Returns an associative array of methods that will transform Expression
     * objects to conform with the specific SQL dialect. Keys are class names
     * and values a method in this class.
     *
     * @psalm-return array<class-string, string>
     * @return array<string>
     */
    protected auto _expressionTranslators(): array
    {
        return [];
    }

    /**
     * Apply translation steps to select queries.
     *
     * @param \Cake\Database\Query myQuery The query to translate
     * @return \Cake\Database\Query The modified query
     */
    protected auto _selectQueryTranslator(Query myQuery): Query
    {
        return this._transformDistinct(myQuery);
    }

    /**
     * Returns the passed query after rewriting the DISTINCT clause, so that drivers
     * that do not support the "ON" part can provide the actual way it should be done
     *
     * @param \Cake\Database\Query myQuery The query to be transformed
     * @return \Cake\Database\Query
     */
    protected auto _transformDistinct(Query myQuery): Query
    {
        if (is_array(myQuery.clause('distinct'))) {
            myQuery.group(myQuery.clause('distinct'), true);
            myQuery.distinct(false);
        }

        return myQuery;
    }

    /**
     * Apply translation steps to delete queries.
     *
     * Chops out aliases on delete query conditions as most database dialects do not
     * support aliases in delete queries. This also removes aliases
     * in table names as they frequently don't work either.
     *
     * We are intentionally not supporting deletes with joins as they have even poorer support.
     *
     * @param \Cake\Database\Query myQuery The query to translate
     * @return \Cake\Database\Query The modified query
     */
    protected auto _deleteQueryTranslator(Query myQuery): Query
    {
        $hadAlias = false;
        myTables = [];
        foreach (myQuery.clause('from') as myAlias => myTable) {
            if (is_string(myAlias)) {
                $hadAlias = true;
            }
            myTables[] = myTable;
        }
        if ($hadAlias) {
            myQuery.from(myTables, true);
        }

        if (!$hadAlias) {
            return myQuery;
        }

        return this._removeAliasesFromConditions(myQuery);
    }

    /**
     * Apply translation steps to update queries.
     *
     * Chops out aliases on update query conditions as not all database dialects do support
     * aliases in update queries.
     *
     * Just like for delete queries, joins are currently not supported for update queries.
     *
     * @param \Cake\Database\Query myQuery The query to translate
     * @return \Cake\Database\Query The modified query
     */
    protected auto _updateQueryTranslator(Query myQuery): Query
    {
        return this._removeAliasesFromConditions(myQuery);
    }

    /**
     * Removes aliases from the `WHERE` clause of a query.
     *
     * @param \Cake\Database\Query myQuery The query to process.
     * @return \Cake\Database\Query The modified query.
     * @throws \RuntimeException In case the processed query contains any joins, as removing
     *  aliases from the conditions can break references to the joined tables.
     */
    protected auto _removeAliasesFromConditions(Query myQuery): Query
    {
        if (myQuery.clause('join')) {
            throw new RuntimeException(
                'Aliases are being removed from conditions for UPDATE/DELETE queries, ' .
                'this can break references to joined tables.'
            );
        }

        $conditions = myQuery.clause('where');
        if ($conditions) {
            $conditions.traverse(function ($expression) {
                if ($expression instanceof ComparisonExpression) {
                    myField = $expression.getField();
                    if (
                        is_string(myField) &&
                        strpos(myField, '.') !== false
                    ) {
                        [, $unaliasedField] = explode('.', myField, 2);
                        $expression.setField($unaliasedField);
                    }

                    return $expression;
                }

                if ($expression instanceof IdentifierExpression) {
                    myIdentifier = $expression.getIdentifier();
                    if (strpos(myIdentifier, '.') !== false) {
                        [, $unaliasedIdentifier] = explode('.', myIdentifier, 2);
                        $expression.setIdentifier($unaliasedIdentifier);
                    }

                    return $expression;
                }

                return $expression;
            });
        }

        return myQuery;
    }

    /**
     * Apply translation steps to insert queries.
     *
     * @param \Cake\Database\Query myQuery The query to translate
     * @return \Cake\Database\Query The modified query
     */
    protected auto _insertQueryTranslator(Query myQuery): Query
    {
        return myQuery;
    }

    /**
     * Returns a SQL snippet for creating a new transaction savepoint
     *
     * @param string|int myName save point name
     * @return string
     */
    string savePointSQL(myName)
    {
        return 'SAVEPOINT LEVEL' . myName;
    }

    /**
     * Returns a SQL snippet for releasing a previously created save point
     *
     * @param string|int myName save point name
     * @return string
     */
    string releaseSavePointSQL(myName)
    {
        return 'RELEASE SAVEPOINT LEVEL' . myName;
    }

    /**
     * Returns a SQL snippet for rollbacking a previously created save point
     *
     * @param string|int myName save point name
     * @return string
     */
    string rollbackSavePointSQL(myName)
    {
        return 'ROLLBACK TO SAVEPOINT LEVEL' . myName;
    }
}
