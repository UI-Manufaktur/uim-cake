


 *


 * @since         3.0.0
  */
module uim.cake.Database;

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
    protected $_driver;

    /**
     * Constructor
     *
     * @param uim.cake.Database\Driver $driver The driver instance used to do the identifier quoting
     */
    public this(Driver $driver) {
        _driver = $driver;
    }

    /**
     * Iterates over each of the clauses in a query looking for identifiers and
     * quotes them
     *
     * @param uim.cake.Database\Query $query The query to have its identifiers quoted
     * @return uim.cake.Database\Query
     */
    function quote(Query $query): Query
    {
        $binder = $query.getValueBinder();
        $query.setValueBinder(null);

        if ($query.type() == "insert") {
            _quoteInsert($query);
        } elseif ($query.type() == "update") {
            _quoteUpdate($query);
        } else {
            _quoteParts($query);
        }

        $query.traverseExpressions([this, "quoteExpression"]);
        $query.setValueBinder($binder);

        return $query;
    }

    /**
     * Quotes identifiers inside expression objects
     *
     * @param uim.cake.Database\IExpression $expression The expression object to walk and quote.
     * @return void
     */
    function quoteExpression(IExpression $expression): void
    {
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
     * @param uim.cake.Database\Query $query The query to quote.
     * @return void
     */
    protected function _quoteParts(Query $query): void
    {
        foreach (["distinct", "select", "from", "group"] as $part) {
            $contents = $query.clause($part);

            if (!is_array($contents)) {
                continue;
            }

            $result = _basicQuoter($contents);
            if (!empty($result)) {
                $query.{$part}($result, true);
            }
        }

        $joins = $query.clause("join");
        if ($joins) {
            $joins = _quoteJoins($joins);
            $query.join($joins, [], true);
        }
    }

    /**
     * A generic identifier quoting function used for various parts of the query
     *
     * @param array<string, mixed> $part the part of the query to quote
     * @return array<string, mixed>
     */
    protected function _basicQuoter(array $part): array
    {
        $result = [];
        foreach ($part as $alias: $value) {
            $value = !is_string($value) ? $value : _driver.quoteIdentifier($value);
            $alias = is_numeric($alias) ? $alias : _driver.quoteIdentifier($alias);
            $result[$alias] = $value;
        }

        return $result;
    }

    /**
     * Quotes both the table and alias for an array of joins as stored in a Query
     * object
     *
     * @param array $joins The joins to quote.
     * @return array<string, array>
     */
    protected function _quoteJoins(array $joins): array
    {
        $result = [];
        foreach ($joins as $value) {
            $alias = "";
            if (!empty($value["alias"])) {
                $alias = _driver.quoteIdentifier($value["alias"]);
                $value["alias"] = $alias;
            }

            if (is_string($value["table"])) {
                $value["table"] = _driver.quoteIdentifier($value["table"]);
            }

            $result[$alias] = $value;
        }

        return $result;
    }

    /**
     * Quotes the table name and columns for an insert query
     *
     * @param uim.cake.Database\Query $query The insert query to quote.
     * @return void
     */
    protected function _quoteInsert(Query $query): void
    {
        $insert = $query.clause("insert");
        if (!isset($insert[0]) || !isset($insert[1])) {
            return;
        }
        [$table, $columns] = $insert;
        $table = _driver.quoteIdentifier($table);
        foreach ($columns as &$column) {
            if (is_scalar($column)) {
                $column = _driver.quoteIdentifier((string)$column);
            }
        }
        $query.insert($columns).into($table);
    }

    /**
     * Quotes the table name for an update query
     *
     * @param uim.cake.Database\Query $query The update query to quote.
     * @return void
     */
    protected function _quoteUpdate(Query $query): void
    {
        $table = $query.clause("update")[0];

        if (is_string($table)) {
            $query.update(_driver.quoteIdentifier($table));
        }
    }

    /**
     * Quotes identifiers in expression objects implementing the field interface
     *
     * @param uim.cake.Database\Expression\FieldInterface $expression The expression to quote.
     * @return void
     */
    protected function _quoteComparison(FieldInterface $expression): void
    {
        $field = $expression.getField();
        if (is_string($field)) {
            $expression.setField(_driver.quoteIdentifier($field));
        } elseif (is_array($field)) {
            $quoted = [];
            foreach ($field as $f) {
                $quoted[] = _driver.quoteIdentifier($f);
            }
            $expression.setField($quoted);
        } elseif ($field instanceof IExpression) {
            this.quoteExpression($field);
        }
    }

    /**
     * Quotes identifiers in "order by" expression objects
     *
     * Strings with spaces are treated as literal expressions
     * and will not have identifiers quoted.
     *
     * @param uim.cake.Database\Expression\OrderByExpression $expression The expression to quote.
     * @return void
     */
    protected function _quoteOrderBy(OrderByExpression $expression): void
    {
        $expression.iterateParts(function ($part, &$field) {
            if (is_string($field)) {
                $field = _driver.quoteIdentifier($field);

                return $part;
            }
            if (is_string($part) && strpos($part, " ") == false) {
                return _driver.quoteIdentifier($part);
            }

            return $part;
        });
    }

    /**
     * Quotes identifiers in "order by" expression objects
     *
     * @param uim.cake.Database\Expression\IdentifierExpression $expression The identifiers to quote.
     * @return void
     */
    protected function _quoteIdentifierExpression(IdentifierExpression $expression): void
    {
        $expression.setIdentifier(
            _driver.quoteIdentifier($expression.getIdentifier())
        );
    }
}
