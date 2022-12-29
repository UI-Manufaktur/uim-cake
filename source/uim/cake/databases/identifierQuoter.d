module uim.cake.databases;

import uim.cake.databases.expressions.FieldInterface;
import uim.cake.databases.expressions.IdentifierExpression;
import uim.cake.databases.expressions.OrderByExpression;

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
     * @var uim.cake.Database\Driver
     */
    protected _driver;

    /**
     * Constructor
     *
     * @param uim.cake.Database\Driver myDriver The driver instance used to do the identifier quoting
     */
    this(Driver myDriver) {
        _driver = myDriver;
    }

    /**
     * Iterates over each of the clauses in a query looking for identifiers and
     * quotes them
     *
     * @param uim.cake.Database\Query myQuery The query to have its identifiers quoted
     * @return uim.cake.Database\Query
     */
    function quote(Query myQuery): Query
    {
        $binder = myQuery.getValueBinder();
        myQuery.setValueBinder(null);

        if (myQuery.type() == "insert") {
            _quoteInsert(myQuery);
        } elseif (myQuery.type() == "update") {
            _quoteUpdate(myQuery);
        } else {
            _quoteParts(myQuery);
        }

        myQuery.traverseExpressions([this, "quoteExpression"]);
        myQuery.setValueBinder($binder);

        return myQuery;
    }

    /**
     * Quotes identifiers inside expression objects
     *
     * @param uim.cake.Database\IExpression $expression The expression object to walk and quote.
     */
    void quoteExpression(IExpression $expression) {
        if ($expression instanceof FieldInterface) {
            _quoteComparison($expression);

            return;
        }

        if ($expression instanceof OrderByExpression) {
            _quoteOrderBy($expression);

            return;
        }

        if ($expression instanceof IdentifierExpression) {
            _quoteIdentifierExpression($expression);

            return;
        }
    }

    /**
     * Quotes all identifiers in each of the clauses of a query
     *
     * @param uim.cake.Database\Query myQuery The query to quote.
     */
    protected void _quoteParts(Query myQuery) {
        foreach (["distinct", "select", "from", "group"] as $part) {
            myContentss = myQuery.clause($part);

            if (!is_array(myContentss)) {
                continue;
            }

            myResult = _basicQuoter(myContentss);
            if (!empty(myResult)) {
                myQuery.{$part}(myResult, true);
            }
        }

        $joins = myQuery.clause("join");
        if ($joins) {
            $joins = _quoteJoins($joins);
            myQuery.join($joins, [], true);
        }
    }

    /**
     * A generic identifier quoting function used for various parts of the query
     *
     * @param array $part the part of the query to quote
     * @return array
     */
    protected array _basicQuoter(array $part) {
        myResult = [];
        foreach ($part as myAlias: myValue) {
            myValue = !is_string(myValue) ? myValue : _driver.quoteIdentifier(myValue);
            myAlias = is_numeric(myAlias) ? myAlias : _driver.quoteIdentifier(myAlias);
            myResult[myAlias] = myValue;
        }

        return myResult;
    }

    /**
     * Quotes both the table and alias for an array of joins as stored in a Query object
     *
     * @param array $joins The joins to quote.
     */
    protected array _quoteJoins(array $joins) {
        myResult = [];
        foreach ($joins as myValue) {
            myAlias = "";
            if (!empty(myValue["alias"])) {
                myAlias = _driver.quoteIdentifier(myValue["alias"]);
                myValue["alias"] = myAlias;
            }

            if (is_string(myValue["table"])) {
                myValue["table"] = _driver.quoteIdentifier(myValue["table"]);
            }

            myResult[myAlias] = myValue;
        }

        return myResult;
    }

    /**
     * Quotes the table name and columns for an insert query
     *
     * @param uim.cake.Database\Query myQuery The insert query to quote.
     */
    protected auto _quoteInsert(Query myQuery) {
        $insert = myQuery.clause("insert");
        if (!isset($insert[0]) || !isset($insert[1])) {
            return;
        }
        [myTable, $columns] = $insert;
        myTable = _driver.quoteIdentifier(myTable);
        foreach ($columns as &$column) {
            if (is_scalar($column)) {
                $column = _driver.quoteIdentifier((string)$column);
            }
        }
        myQuery.insert($columns).into(myTable);
    }

    /**
     * Quotes the table name for an update query
     *
     * @param uim.cake.Database\Query myQuery The update query to quote.
     */
    protected void _quoteUpdate(Query myQuery) {
        myTable = myQuery.clause("update")[0];

        if (is_string(myTable)) {
            myQuery.update(_driver.quoteIdentifier(myTable));
        }
    }

    /**
     * Quotes identifiers in expression objects implementing the field interface
     *
     * @param uim.cake.Database\Expression\FieldInterface $expression The expression to quote.
     */
    protected void _quoteComparison(FieldInterface $expression) {
        myField = $expression.getField();
        if (is_string(myField)) {
            $expression.setField(_driver.quoteIdentifier(myField));
        } elseif (is_array(myField)) {
            $quoted = [];
            foreach (myField as $f) {
                $quoted[] = _driver.quoteIdentifier($f);
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
     * @param uim.cake.Database\Expression\OrderByExpression $expression The expression to quote.
     */
    protected void _quoteOrderBy(OrderByExpression $expression) {
        $expression.iterateParts(function ($part, &myField) {
            if (is_string(myField)) {
                myField = _driver.quoteIdentifier(myField);

                return $part;
            }
            if (is_string($part) && indexOf($part, " ") == false) {
                return _driver.quoteIdentifier($part);
            }

            return $part;
        });
    }

    /**
     * Quotes identifiers in "order by" expression objects
     *
     * @param uim.cake.Database\Expression\IdentifierExpression $expression The identifiers to quote.
     */
    protected void _quoteIdentifierExpression(IdentifierExpression $expression) {
        $expression.setIdentifier(
            _driver.quoteIdentifier($expression.getIdentifier())
        );
    }
}
