module uim.cake.database.Expression;

import uim.cake.database.Exception\DatabaseException;
import uim.cake.database.IExpression;
import uim.cake.database.Query;
import uim.cake.database.Type\ExpressionTypeCasterTrait;
import uim.cake.database.TypeMap;
import uim.cake.database.TypeMapTrait;
import uim.cake.database.ValueBinder;
use Closure;

/**
 * An expression object to contain values being inserted.
 *
 * Helps generate SQL with the correct number of placeholders and bind
 * values correctly into the statement.
 */
class ValuesExpression : IExpression
{
    use ExpressionTypeCasterTrait;
    use TypeMapTrait;

    /**
     * Array of values to insert.
     *
     * @var array
     */
    protected $_values = [];

    /**
     * List of columns to ensure are part of the insert.
     *
     * @var array
     */
    protected $_columns = [];

    /**
     * The Query object to use as a values expression
     *
     * @var \Cake\Database\Query|null
     */
    protected $_query;

    /**
     * Whether values have been casted to expressions
     * already.
     *
     * @var bool
     */
    protected $_castedExpressions = false;

    /**
     * Constructor
     *
     * @param array $columns The list of columns that are going to be part of the values.
     * @param \Cake\Database\TypeMap myTypeMap A dictionary of column . type names
     */
    this(array $columns, TypeMap myTypeMap)
    {
        this._columns = $columns;
        this.setTypeMap(myTypeMap);
    }

    /**
     * Add a row of data to be inserted.
     *
     * @param \Cake\Database\Query|array myValues Array of data to append into the insert, or
     *   a query for doing INSERT INTO .. SELECT style commands
     * @return void
     * @throws \Cake\Database\Exception\DatabaseException When mixing array + Query data types.
     */
    function add(myValues): void
    {
        if (
            (
                count(this._values) &&
                myValues instanceof Query
            ) ||
            (
                this._query &&
                is_array(myValues)
            )
        ) {
            throw new DatabaseException(
                'You cannot mix subqueries and array values in inserts.'
            );
        }
        if (myValues instanceof Query) {
            this.setQuery(myValues);

            return;
        }
        this._values[] = myValues;
        this._castedExpressions = false;
    }

    /**
     * Sets the columns to be inserted.
     *
     * @param array $columns Array with columns to be inserted.
     * @return this
     */
    auto setColumns(array $columns)
    {
        this._columns = $columns;
        this._castedExpressions = false;

        return this;
    }

    /**
     * Gets the columns to be inserted.
     *
     * @return array
     */
    auto getColumns(): array
    {
        return this._columns;
    }

    /**
     * Get the bare column names.
     *
     * Because column names could be identifier quoted, we
     * need to strip the identifiers off of the columns.
     *
     * @return array
     */
    protected auto _columnNames(): array
    {
        $columns = [];
        foreach (this._columns as $col) {
            if (is_string($col)) {
                $col = trim($col, '`[]"');
            }
            $columns[] = $col;
        }

        return $columns;
    }

    /**
     * Sets the values to be inserted.
     *
     * @param array myValues Array with values to be inserted.
     * @return this
     */
    auto setValues(array myValues)
    {
        this._values = myValues;
        this._castedExpressions = false;

        return this;
    }

    /**
     * Gets the values to be inserted.
     *
     * @return array
     */
    auto getValues(): array
    {
        if (!this._castedExpressions) {
            this._processExpressions();
        }

        return this._values;
    }

    /**
     * Sets the query object to be used as the values expression to be evaluated
     * to insert records in the table.
     *
     * @param \Cake\Database\Query myQuery The query to set
     * @return this
     */
    auto setQuery(Query myQuery)
    {
        this._query = myQuery;

        return this;
    }

    /**
     * Gets the query object to be used as the values expression to be evaluated
     * to insert records in the table.
     *
     * @return \Cake\Database\Query|null
     */
    auto getQuery(): ?Query
    {
        return this._query;
    }

    /**
     * @inheritDoc
     */
    function sql(ValueBinder $binder): string
    {
        if (empty(this._values) && empty(this._query)) {
            return '';
        }

        if (!this._castedExpressions) {
            this._processExpressions();
        }

        $columns = this._columnNames();
        $defaults = array_fill_keys($columns, null);
        $placeholders = [];

        myTypes = [];
        myTypeMap = this.getTypeMap();
        foreach ($defaults as $col => $v) {
            myTypes[$col] = myTypeMap.type($col);
        }

        foreach (this._values as $row) {
            $row += $defaults;
            $rowPlaceholders = [];

            foreach ($columns as $column) {
                myValue = $row[$column];

                if (myValue instanceof IExpression) {
                    $rowPlaceholders[] = '(' . myValue.sql($binder) . ')';
                    continue;
                }

                $placeholder = $binder.placeholder('c');
                $rowPlaceholders[] = $placeholder;
                $binder.bind($placeholder, myValue, myTypes[$column]);
            }

            $placeholders[] = implode(', ', $rowPlaceholders);
        }

        myQuery = this.getQuery();
        if (myQuery) {
            return ' ' . myQuery.sql($binder);
        }

        return sprintf(' VALUES (%s)', implode('), (', $placeholders));
    }

    /**
     * @inheritDoc
     */
    function traverse(Closure $callback)
    {
        if (this._query) {
            return this;
        }

        if (!this._castedExpressions) {
            this._processExpressions();
        }

        foreach (this._values as $v) {
            if ($v instanceof IExpression) {
                $v.traverse($callback);
            }
            if (!is_array($v)) {
                continue;
            }
            foreach ($v as myField) {
                if (myField instanceof IExpression) {
                    $callback(myField);
                    myField.traverse($callback);
                }
            }
        }

        return this;
    }

    /**
     * Converts values that need to be casted to expressions
     *
     * @return void
     */
    protected auto _processExpressions(): void
    {
        myTypes = [];
        myTypeMap = this.getTypeMap();

        $columns = this._columnNames();
        foreach ($columns as $c) {
            if (!is_string($c) && !is_int($c)) {
                continue;
            }
            myTypes[$c] = myTypeMap.type($c);
        }

        myTypes = this._requiresToExpressionCasting(myTypes);

        if (empty(myTypes)) {
            return;
        }

        foreach (this._values as $row => myValues) {
            foreach (myTypes as $col => myType) {
                /** @var \Cake\Database\Type\ExpressionTypeInterface myType */
                this._values[$row][$col] = myType.toExpression(myValues[$col]);
            }
        }
        this._castedExpressions = true;
    }
}
