module uim.cake.databases.Driver;

import uim.cake.databases.Driver;
import uim.cake.databases.expressions.FunctionExpression;
import uim.cake.databases.expressions.IdentifierExpression;
import uim.cake.databases.expressions.StringExpression;
import uim.cake.databases.PostgresCompiler;
import uim.cake.databases.Query;
import uim.cake.databases.QueryCompiler;
import uim.cake.databases.schemas.PostgresSchemaDialect;
import uim.cake.databases.schemas.SchemaDialect;
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
        "persistent": true,
        "host": "localhost",
        "username": "root",
        "password": "",
        "database": "cake",
        "schema": "public",
        "port": 5432,
        "encoding": "utf8",
        "timezone": null,
        "flags": [],
        "init": [],
    ];

    /**
     * The schema dialect class for this driver
     *
     * @var uim.cake.databases.Schema\PostgresSchemaDialect|null
     */
    protected $_schemaDialect;

    /**
     * String used to start a database identifier quoting to make it safe
     *
     */
    protected string $_startQuote = """;

    /**
     * String used to end a database identifier quoting to make it safe
     *
     */
    protected string $_endQuote = """;

    /**
     * Establishes a connection to the database server
     *
     * @return bool true on success
     */
    function connect(): bool
    {
        if (_connection) {
            return true;
        }
        $config = _config;
        $config["flags"] += [
            PDO::ATTR_PERSISTENT: $config["persistent"],
            PDO::ATTR_EMULATE_PREPARES: false,
            PDO::ATTR_ERRMODE: PDO::ERRMODE_EXCEPTION,
        ];
        if (empty($config["unix_socket"])) {
            $dsn = "pgsql:host={$config["host"]};port={$config["port"]};dbname={$config["database"]}";
        } else {
            $dsn = "pgsql:dbname={$config["database"]}";
        }

        _connect($dsn, $config);
        _connection = $connection = this.getConnection();
        if (!empty($config["encoding"])) {
            this.setEncoding($config["encoding"]);
        }

        if (!empty($config["schema"])) {
            this.setSchema($config["schema"]);
        }

        if (!empty($config["timezone"])) {
            $config["init"][] = sprintf("SET timezone = %s", $connection.quote($config["timezone"]));
        }

        foreach ($config["init"] as $command) {
            $connection.exec($command);
        }

        return true;
    }

    /**
     * Returns whether php is able to use this driver for connecting to database
     *
     * @return bool true if it is valid to use this driver
     */
    function enabled(): bool
    {
        return in_array("pgsql", PDO::getAvailableDrivers(), true);
    }


    function schemaDialect(): SchemaDialect
    {
        if (_schemaDialect == null) {
            _schemaDialect = new PostgresSchemaDialect(this);
        }

        return _schemaDialect;
    }

    /**
     * Sets connection encoding
     *
     * @param string $encoding The encoding to use.
     */
    void setEncoding(string $encoding) {
        this.connect();
        _connection.exec("SET NAMES " ~ _connection.quote($encoding));
    }

    /**
     * Sets connection default schema, if any relation defined in a query is not fully qualified
     * postgres will fallback to looking the relation into defined default schema
     *
     * @param string $schema The schema names to set `search_path` to.
     */
    void setSchema(string $schema) {
        this.connect();
        _connection.exec("SET search_path TO " ~ _connection.quote($schema));
    }


    string disableForeignKeySQL()
    {
        return "SET CONSTRAINTS ALL DEFERRED";
    }


    string enableForeignKeySQL()
    {
        return "SET CONSTRAINTS ALL IMMEDIATE";
    }


    function supports(string $feature): bool
    {
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


    function supportsDynamicConstraints(): bool
    {
        return true;
    }


    protected function _transformDistinct(Query $query): Query
    {
        return $query;
    }


    protected function _insertQueryTranslator(Query $query): Query
    {
        if (!$query.clause("epilog")) {
            $query.epilog("RETURNING *");
        }

        return $query;
    }


    protected function _expressionTranslators(): array
    {
        return [
            IdentifierExpression::class: "_transformIdentifierExpression",
            FunctionExpression::class: "_transformFunctionExpression",
            StringExpression::class: "_transformStringExpression",
        ];
    }

    /**
     * Changes identifer expression into postgresql format.
     *
     * @param uim.cake.databases.Expression\IdentifierExpression $expression The expression to tranform.
     */
    protected void _transformIdentifierExpression(IdentifierExpression $expression) {
        $collation = $expression.getCollation();
        if ($collation) {
            // use trim() to work around expression being transformed multiple times
            $expression.setCollation(""" ~ trim($collation, """) ~ """);
        }
    }

    /**
     * Receives a FunctionExpression and changes it so that it conforms to this
     * SQL dialect.
     *
     * @param uim.cake.databases.Expression\FunctionExpression $expression The function expression to convert
     *   to postgres SQL.
     */
    protected void _transformFunctionExpression(FunctionExpression $expression) {
        switch ($expression.getName()) {
            case "CONCAT":
                // CONCAT function is expressed as exp1 || exp2
                $expression.setName("").setConjunction(" ||");
                break;
            case "DATEDIFF":
                $expression
                    .setName("")
                    .setConjunction("-")
                    .iterateParts(function ($p) {
                        if (is_string($p)) {
                            $p = ["value": [$p: "literal"], "type": null];
                        } else {
                            $p["value"] = [$p["value"]];
                        }

                        return new FunctionExpression("DATE", $p["value"], [$p["type"]]);
                    });
                break;
            case "CURRENT_DATE":
                $time = new FunctionExpression("LOCALTIMESTAMP", [" 0 ": "literal"]);
                $expression.setName("CAST").setConjunction(" AS ").add([$time, "date": "literal"]);
                break;
            case "CURRENT_TIME":
                $time = new FunctionExpression("LOCALTIMESTAMP", [" 0 ": "literal"]);
                $expression.setName("CAST").setConjunction(" AS ").add([$time, "time": "literal"]);
                break;
            case "NOW":
                $expression.setName("LOCALTIMESTAMP").add([" 0 ": "literal"]);
                break;
            case "RAND":
                $expression.setName("RANDOM");
                break;
            case "DATE_ADD":
                $expression
                    .setName("")
                    .setConjunction(" + INTERVAL")
                    .iterateParts(function ($p, $key) {
                        if ($key == 1) {
                            $p = sprintf(""%s"", $p);
                        }

                        return $p;
                    });
                break;
            case "DAYOFWEEK":
                $expression
                    .setName("EXTRACT")
                    .setConjunction(" ")
                    .add(["DOW FROM": "literal"], [], true)
                    .add([") + (1": "literal"]); // Postgres starts on index 0 but Sunday should be 1
                break;
        }
    }

    /**
     * Changes string expression into postgresql format.
     *
     * @param uim.cake.databases.Expression\StringExpression $expression The string expression to tranform.
     */
    protected void _transformStringExpression(StringExpression $expression) {
        // use trim() to work around expression being transformed multiple times
        $expression.setCollation(""" ~ trim($expression.getCollation(), """) ~ """);
    }

    /**
     * {@inheritDoc}
     *
     * @return uim.cake.databases.PostgresCompiler
     */
    function newCompiler(): QueryCompiler
    {
        return new PostgresCompiler();
    }
}