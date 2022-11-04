module uim.cake.database;

import uim.cake.database.Expression\FieldInterface;
import uim.cake.database.Expression\IdentifierExpression;
import uim.cake.database.Expression\OrderByExpression;

/**
 * Contains all the logic related to quoting identifiers in a Query object
 *
 * @internal
 */
class IdentifierQuoter
{
    /**
     * The driver instance used to do the identifier quoting
     *
     * @var \Cake\Database\Driver
     */
    protected $_driver;

    /**
     * Constructor
     *
     * @param \Cake\Database\Driver myDriver The driver instance used to do the identifier quoting
     */
    this(Driver myDriver) {
        this._driver = myDriver;
    }

    /**
     * Iterates over each of the clauses in a query looking for identifiers and
     * quotes them
     *
     * @param \Cake\Database\Query myQuery The query to have its identifiers quoted
     * @return \Cake\Database\Query
     */
    function quote(Query myQuery): Query
    {
        $binder = myQuery.getValueBinder();
        myQuery.setValueBinder(null);

        if (myQuery.type() === 'insert') {
            this._quoteInsert(myQuery);
        } elseif (myQuery.type() === 'update') {
            this._quoteUpdate(myQuery);
        } else {
            this._quoteParts(myQuery);
        }

        myQuery.traverseExpressions([this, 'quoteExpression']);
        myQuery.setValueBinder($binder);

        return myQuery;
    }

    /**
     * Quotes identifiers inside expression objects
     *
     * @param \Cake\Database\IExpression $expression The expression object to walk and quote.
     * @return void
     */
    function quoteExpression(IExpression $expression): void
    {
        if ($expression instanceof FieldInterface) {
            this._quoteComparison($expression);

            return;
        }

        if ($expression instanceof OrderByExpression) {
            this._quoteOrderBy($expression);

            return;
        }

        if ($expression instanceof IdentifierExpression) {
            this._quoteIdentifierExpression($expression);

            return;
        }
    }

    /**
     * Quotes all identifiers in each of the clauses of a query
     *
     * @param \Cake\Database\Query myQuery The query to quote.
     * @return void
     */
    protected auto _quoteParts(Query myQuery): void
    {
        foreach (['distinct', 'select', 'from', 'group'] as $part) {
            myContentss = myQuery.clause($part);

            if (!is_array(myContentss)) {
                continue;
            }

            myResult = this._basicQuoter(myContentss);
            if (!empty(myResult)) {
                myQuery.{$part}(myResult, true);
            }
        }

        $joins = myQuery.clause('join');
        if ($joins) {
            $joins = this._quoteJoins($joins);
            myQuery.join($joins, [], true);
        }
    }

    /**
     * A generic identifier quoting function used for various parts of the query
     *
     * @param array $part the part of the query to quote
     * @return array
     */
    protected auto _basicQuoter(array $part): array
    {
        myResult = [];
        foreach ($part as myAlias => myValue) {
            myValue = !is_string(myValue) ? myValue : this._driver.quoteIdentifier(myValue);
            myAlias = is_numeric(myAlias) ? myAlias : this._driver.quoteIdentifier(myAlias);
            myResult[myAlias] = myValue;
        }

        return myResult;
    }

    /**
     * Quotes both the table and alias for an array of joins as stored in a Query
     * object
     *
     * @param array $joins The joins to quote.
     * @return array
     */
    protected auto _quoteJoins(array $joins): array
    {
        myResult = [];
        foreach ($joins as myValue) {
            myAlias = '';
            if (!empty(myValue['alias'])) {
                myAlias = this._driver.quoteIdentifier(myValue['alias']);
                myValue['alias'] = myAlias;
            }

            if (is_string(myValue['table'])) {
                myValue['table'] = this._driver.quoteIdentifier(myValue['table']);
            }

            myResult[myAlias] = myValue;
        }

        return myResult;
    }

    /**
     * Quotes the table name and columns for an insert query
     *
     * @param \Cake\Database\Query myQuery The insert query to quote.
     * @return void
     */
    protected auto _quoteInsert(Query myQuery): void
    {
        $insert = myQuery.clause('insert');
        if (!isset($insert[0]) || !isset($insert[1])) {
            return;
        }
        [myTable, $columns] = $insert;
        myTable = this._driver.quoteIdentifier(myTable);
        foreach ($columns as &$column) {
            if (is_scalar($column)) {
                $column = this._driver.quoteIdentifier((string)$column);
            }
        }
        myQuery.insert($columns).into(myTable);
    }

    /**
     * Quotes the table name for an update query
     *
     * @param \Cake\Database\Query myQuery The update query to quote.
     * @return void
     */
    protected auto _quoteUpdate(Query myQuery): void
    {
        myTable = myQuery.clause('update')[0];

        if (is_string(myTable)) {
            myQuery.update(this._driver.quoteIdentifier(myTable));
        }
    }

    /**
     * Quotes identifiers in expression objects implementing the field interface
     *
     * @param \Cake\Database\Expression\FieldInterface $expression The expression to quote.
     * @return void
     */
    protected auto _quoteComparison(FieldInterface $expression): void
    {
        myField = $expression.getField();
        if (is_string(myField)) {
            $expression.setField(this._driver.quoteIdentifier(myField));
        } elseif (is_array(myField)) {
            $quoted = [];
            foreach (myField as $f) {
                $quoted[] = this._driver.quoteIdentifier($f);
            }
            $expression.setField($quoted);
        } elseif (myField instanceof IExpression) {
            this.quoteExpression(myField);
        }
    }

    /**
     * Quotes identifiers in "order by" expression objects
     *
     * Strings with spaces are treated as literal expressions
     * and will not have identifiers quoted.
     *
     * @param \Cake\Database\Expression\OrderByExpression $expression The expression to quote.
     * @return void
     */
    protected auto _quoteOrderBy(OrderByExpression $expression): void
    {
        $expression.iterateParts(function ($part, &myField) {
            if (is_string(myField)) {
                myField = this._driver.quoteIdentifier(myField);

                return $part;
            }
            if (is_string($part) && strpos($part, ' ') === false) {
                return this._driver.quoteIdentifier($part);
            }

            return $part;
        });
    }

    /**
     * Quotes identifiers in "order by" expression objects
     *
     * @param \Cake\Database\Expression\IdentifierExpression $expression The identifiers to quote.
     * @return void
     */
    protected auto _quoteIdentifierExpression(IdentifierExpression $expression): void
    {
        $expression.setIdentifier(
            this._driver.quoteIdentifier($expression.getIdentifier())
        );
    }
}
