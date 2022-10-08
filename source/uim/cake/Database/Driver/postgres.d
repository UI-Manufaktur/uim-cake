module uim.cake.database.Driver;

import uim.cake.database.Driver;
import uim.cake.database.Expression\FunctionExpression;
import uim.cake.database.Expression\IdentifierExpression;
import uim.cake.database.Expression\StringExpression;
import uim.cake.database.PostgresCompiler;
import uim.cake.database.Query;
import uim.cake.database.QueryCompiler;
import uim.cake.database.Schema\PostgresSchemaDialect;
import uim.cake.database.Schema\SchemaDialect;
use PDO;

/**
 * Class Postgres
 */
class Postgres : Driver
{
    use SqlDialectTrait;


    protected const MAX_ALIAS_LENGTH = 63;

    /**
     * Base configuration settings for Postgres driver
     *
     * @var array<string, mixed>
     */
    protected $_baseConfig = [
        'persistent' => true,
        'host' => 'localhost',
        'username' => 'root',
        'password' => '',
        'database' => 'cake',
        'schema' => 'public',
        'port' => 5432,
        'encoding' => 'utf8',
        'timezone' => null,
        'flags' => [],
        'init' => [],
    ];

    /**
     * The schema dialect class for this driver
     *
     * @var \Cake\Database\Schema\PostgresSchemaDialect|null
     */
    protected $_schemaDialect;

    /**
     * String used to start a database identifier quoting to make it safe
     *
     * @var string
     */
    protected $_startQuote = '"';

    /**
     * String used to end a database identifier quoting to make it safe
     *
     * @var string
     */
    protected $_endQuote = '"';

    /**
     * Establishes a connection to the database server
     *
     * @return bool true on success
     */
    bool connect() {
        if (this._connection) {
            return true;
        }
        myConfig = this._config;
        myConfig['flags'] += [
            PDO::ATTR_PERSISTENT => myConfig['persistent'],
            PDO::ATTR_EMULATE_PREPARES => false,
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        ];
        if (empty(myConfig['unix_socket'])) {
            $dsn = "pgsql:host={myConfig['host']};port={myConfig['port']};dbname={myConfig['database']}";
        } else {
            $dsn = "pgsql:dbname={myConfig['database']}";
        }

        this._connect($dsn, myConfig);
        this._connection = myConnection = this.getConnection();
        if (!empty(myConfig['encoding'])) {
            this.setEncoding(myConfig['encoding']);
        }

        if (!empty(myConfig['schema'])) {
            this.setSchema(myConfig['schema']);
        }

        if (!empty(myConfig['timezone'])) {
            myConfig['init'][] = sprintf('SET timezone = %s', myConnection.quote(myConfig['timezone']));
        }

        foreach (myConfig['init'] as $command) {
            myConnection.exec($command);
        }

        return true;
    }

    /**
     * Returns whether php is able to use this driver for connecting to database
     *
     * @return bool true if it is valid to use this driver
     */
    bool enabled() {
        return in_array('pgsql', PDO::getAvailableDrivers(), true);
    }


    function schemaDialect(): SchemaDialect
    {
        if (this._schemaDialect === null) {
            this._schemaDialect = new PostgresSchemaDialect(this);
        }

        return this._schemaDialect;
    }

    /**
     * Sets connection encoding
     *
     * @param string $encoding The encoding to use.
     * @return void
     */
    auto setEncoding(string $encoding): void
    {
        this.connect();
        this._connection.exec('SET NAMES ' . this._connection.quote($encoding));
    }

    /**
     * Sets connection default schema, if any relation defined in a query is not fully qualified
     * postgres will fallback to looking the relation into defined default schema
     *
     * @param string $schema The schema names to set `search_path` to.
     * @return void
     */
    auto setSchema(string $schema): void
    {
        this.connect();
        this._connection.exec('SET search_path TO ' . this._connection.quote($schema));
    }


    function disableForeignKeySQL(): string
    {
        return 'SET CONSTRAINTS ALL DEFERRED';
    }


    function enableForeignKeySQL(): string
    {
        return 'SET CONSTRAINTS ALL IMMEDIATE';
    }


    bool supports(string $feature) {
        switch ($feature) {
            case static::FEATURE_CTE:
            case static::FEATURE_JSON:
            case static::FEATURE_TRUNCATE_WITH_CONSTRAINTS:
            case static::FEATURE_WINDOW:
                return true;

            case static::FEATURE_DISABLE_CONSTRAINT_WITHOUT_TRANSACTION:
                return false;
        }

        return super.supports($feature);
    }


    bool supportsDynamicConstraints() {
        return true;
    }


    protected auto _transformDistinct(Query myQuery): Query
    {
        return myQuery;
    }


    protected auto _insertQueryTranslator(Query myQuery): Query
    {
        if (!myQuery.clause('epilog')) {
            myQuery.epilog('RETURNING *');
        }

        return myQuery;
    }


    protected auto _expressionTranslators(): array
    {
        return [
            IdentifierExpression::class => '_transformIdentifierExpression',
            FunctionExpression::class => '_transformFunctionExpression',
            StringExpression::class => '_transformStringExpression',
        ];
    }

    /**
     * Changes identifer expression into postgresql format.
     *
     * @param \Cake\Database\Expression\IdentifierExpression $expression The expression to tranform.
     * @return void
     */
    protected auto _transformIdentifierExpression(IdentifierExpression $expression): void
    {
        $collation = $expression.getCollation();
        if ($collation) {
            // use trim() to work around expression being transformed multiple times
            $expression.setCollation('"' . trim($collation, '"') . '"');
        }
    }

    /**
     * Receives a FunctionExpression and changes it so that it conforms to this
     * SQL dialect.
     *
     * @param \Cake\Database\Expression\FunctionExpression $expression The function expression to convert
     *   to postgres SQL.
     * @return void
     */
    protected auto _transformFunctionExpression(FunctionExpression $expression): void
    {
        switch ($expression.getName()) {
            case 'CONCAT':
                // CONCAT function is expressed as exp1 || exp2
                $expression.setName('').setConjunction(' ||');
                break;
            case 'DATEDIFF':
                $expression
                    .setName('')
                    .setConjunction('-')
                    .iterateParts(function ($p) {
                        if (is_string($p)) {
                            $p = ['value' => [$p => 'literal'], 'type' => null];
                        } else {
                            $p['value'] = [$p['value']];
                        }

                        return new FunctionExpression('DATE', $p['value'], [$p['type']]);
                    });
                break;
            case 'CURRENT_DATE':
                $time = new FunctionExpression('LOCALTIMESTAMP', [' 0 ' => 'literal']);
                $expression.setName('CAST').setConjunction(' AS ').add([$time, 'date' => 'literal']);
                break;
            case 'CURRENT_TIME':
                $time = new FunctionExpression('LOCALTIMESTAMP', [' 0 ' => 'literal']);
                $expression.setName('CAST').setConjunction(' AS ').add([$time, 'time' => 'literal']);
                break;
            case 'NOW':
                $expression.setName('LOCALTIMESTAMP').add([' 0 ' => 'literal']);
                break;
            case 'RAND':
                $expression.setName('RANDOM');
                break;
            case 'DATE_ADD':
                $expression
                    .setName('')
                    .setConjunction(' + INTERVAL')
                    .iterateParts(function ($p, myKey) {
                        if (myKey === 1) {
                            $p = sprintf("'%s'", $p);
                        }

                        return $p;
                    });
                break;
            case 'DAYOFWEEK':
                $expression
                    .setName('EXTRACT')
                    .setConjunction(' ')
                    .add(['DOW FROM' => 'literal'], [], true)
                    .add([') + (1' => 'literal']); // Postgres starts on index 0 but Sunday should be 1
                break;
        }
    }

    /**
     * Changes string expression into postgresql format.
     *
     * @param \Cake\Database\Expression\StringExpression $expression The string expression to tranform.
     * @return void
     */
    protected auto _transformStringExpression(StringExpression $expression): void
    {
        // use trim() to work around expression being transformed multiple times
        $expression.setCollation('"' . trim($expression.getCollation(), '"') . '"');
    }

    /**
     * {@inheritDoc}
     *
     * @return \Cake\Database\PostgresCompiler
     */
    function newCompiler(): QueryCompiler
    {
        return new PostgresCompiler();
    }
}
