module uim.cake.TestSuite\Fixture;

import uim.cake.core.Configure;
import uim.cake.core.exceptions.UIMException;
import uim.cake.databases.IConstraints;
import uim.cake.databases.schemas.TableSchema;
import uim.cake.databases.schemas.TableSchemaAwareInterface;
import uim.datasources.IConnection;
import uim.datasources.ConnectionManager;
import uim.datasources.IFixture;
import uim.cake.TestSuite\TestCase;
use PDOException;
use RuntimeException;
use UnexpectedValueException;

/**
 * A factory class to manage the life cycle of test fixtures
 */
class FixtureManager
{
    /**
     * Was this instance already initialized?
     */
    protected bool _initialized = false;

    /**
     * Holds the fixture classes that where instantiated
     *
     * @var array<uim.cake.Datasource\IFixture>
     */
    protected _loaded = null;

    /**
     * Holds the fixture classes that where instantiated indexed by class name
     *
     * @var array<uim.cake.Datasource\IFixture>
     */
    protected _fixtureMap = null;

    /**
     * A map of connection names and the fixture currently in it.
     *
     * @var array<string, array<uim.cake.Datasource\IFixture>>
     */
    protected _insertionMap = null;

    /**
     * List of TestCase class name that have been processed
     *
     * @var array<string, bool>
     */
    protected _processed = null;

    /**
     * Is the test runner being run with `--debug` enabled.
     * When true, fixture SQL will also be logged.
     */
    protected bool _debug = false;

    /**
     * Modify the debug mode.
     *
     * @param bool $debug Whether fixture debug mode is enabled.
     */
    void setDebug(bool $debug) {
        _debug = $debug;
    }

    /**
     * @param uim.cake.TestSuite\TestCase $test Test case
     */
    void fixturize(TestCase $test) {
        _initDb();
        if (!$test.getFixtures() || !empty(_processed[get_class($test)])) {
            return;
        }
        _loadFixtures($test);
        _processed[get_class($test)] = true;
    }

    /**
     * @return uim.cake.Datasource\IFixture[]
     */
    array loaded() {
        return _loaded;
    }

    /**
     * @return array<string>
     */
    string[] getInserted() {
        $inserted = null;
        foreach (_insertionMap as $fixtures) {
            foreach ($fixtures as $fixture) {
                /** @var uim.cake.TestSuite\Fixture\TestFixture $fixture */
                $inserted[] = $fixture.table;
            }
        }

        return $inserted;
    }

    /**
     * Add aliases for all non test prefixed connections.
     *
     * This allows models to use the test connections without
     * a pile of configuration work.
     */
    protected void _aliasConnections() {
        $connections = ConnectionManager::configured();
        ConnectionManager::alias("test", "default");
        $map = null;
        foreach ($connections as $connection) {
            if ($connection == "test" || $connection == "default") {
                continue;
            }
            if (isset($map[$connection])) {
                continue;
            }
            if (strpos($connection, "test_") == 0) {
                $map[$connection] = substr($connection, 5);
            } else {
                $map["test_" ~ $connection] = $connection;
            }
        }
        foreach ($map as $testConnection: $normal) {
            ConnectionManager::alias($testConnection, $normal);
        }
    }

    /**
     * Initializes this class with a DataSource object to use as default for all fixtures
     */
    protected void _initDb() {
        if (_initialized) {
            return;
        }
        _aliasConnections();
        _initialized = true;
    }

    /**
     * Looks for fixture files and instantiates the classes accordingly
     *
     * @param uim.cake.TestSuite\TestCase $test The test suite to load fixtures for.
     * @return void
     * @throws \UnexpectedValueException when a referenced fixture does not exist.
     */
    protected void _loadFixtures(TestCase $test) {
        $fixtures = $test.getFixtures();
        if (!$fixtures) {
            return;
        }
        foreach ($fixtures as $fixture) {
            if (isset(_loaded[$fixture])) {
                continue;
            }

            if (strpos($fixture, ".")) {
                [$type, $pathName] = explode(".", $fixture, 2);
                $path = explode("/", $pathName);
                $name = array_pop($path);
                $additionalPath = implode("\\", $path);

                if ($type == "core") {
                    $baseNamespace = "Cake";
                } elseif ($type == "app") {
                    $baseNamespace = Configure::read("App.namespace");
                } elseif ($type == "plugin") {
                    [$plugin, $name] = explode(".", $pathName);
                    $baseNamespace = replace("/", "\\", $plugin);
                    $additionalPath = null;
                } else {
                    $baseNamespace = "";
                    $name = $fixture;
                }

                if (strpos($name, "/") > 0) {
                    $name = replace("/", "\\", $name);
                }

                $nameSegments = [
                    $baseNamespace,
                    "Test\Fixture",
                    $additionalPath,
                    $name ~ "Fixture",
                ];
                /** @psalm-var class-string<uim.cake.Datasource\IFixture> */
                $className = implode("\\", array_filter($nameSegments));
            } else {
                /** @psalm-var class-string<uim.cake.Datasource\IFixture> */
                $className = $fixture;
                /** @psalm-suppress PossiblyFalseArgument */
                $name = preg_replace("/Fixture\z/", "", substr(strrchr($fixture, "\\"), 1));
            }

            if (class_exists($className)) {
                _loaded[$fixture] = new $className();
                _fixtureMap[$name] = _loaded[$fixture];
            } else {
                $msg = sprintf(
                    "Referenced fixture class '%s' not found. Fixture '%s' was referenced in test case '%s'.",
                    $className,
                    $fixture,
                    get_class($test)
                );
                throw new UnexpectedValueException($msg);
            }
        }
    }

    /**
     * Runs the drop and create commands on the fixtures if necessary.
     *
     * @param uim.cake.Datasource\IFixture $fixture the fixture object to create
     * @param uim.cake.Datasource\IConnection $db The Connection object instance to use
     * @param array<string> $sources The existing tables in the datasource.
     * @param bool $drop whether drop the fixture if it is already created or not
     */
    protected void _setupTable(
        IFixture $fixture,
        IConnection $db,
        array $sources,
        bool $drop = true
    ) {
        $configName = $db.configName();
        $isFixtureSetup = this.isFixtureSetup($configName, $fixture);
        if ($isFixtureSetup) {
            return;
        }

        $table = $fixture.sourceName();
        $exists = hasAllValues($table, $sources, true);

        $hasSchema = $fixture instanceof TableSchemaAwareInterface && $fixture.getTableSchema() instanceof TableSchema;

        if (($drop && $exists) || ($exists && $hasSchema)) {
            $fixture.drop($db);
            $fixture.create($db);
        } elseif (!$exists) {
            $fixture.create($db);
        } else {
            $fixture.truncate($db);
        }

        _insertionMap[$configName][] = $fixture;
    }

    /**
     * @param uim.cake.TestSuite\TestCase $test Test case
     * @return void
     * @throws \RuntimeException
     */
    void load(TestCase $test) {
        $fixtures = $test.getFixtures();
        if (!$fixtures || !$test.autoFixtures) {
            return;
        }

        try {
            $createTables = void (IConnection $db, array $fixtures) use ($test) {
                /** @var array<uim.cake.Datasource\IFixture> $fixtures */
                $tables = $db.getSchemaCollection().listTables();
                $configName = $db.configName();
                _insertionMap[$configName] = _insertionMap[$configName] ?? [];

                foreach ($fixtures as $fixture) {
                    if (!$fixture instanceof IConstraints) {
                        continue;
                    }

                    if (hasAllValues($fixture.sourceName(), $tables, true)) {
                        try {
                            $fixture.dropConstraints($db);
                        } catch (PDOException $e) {
                            $msg = sprintf(
                                "Unable to drop constraints for fixture '%s' in '%s' test case: " ~ "\n" ~ '%s',
                                get_class($fixture),
                                get_class($test),
                                $e.getMessage()
                            );
                            throw new UIMException($msg, null, $e);
                        }
                    }
                }

                foreach ($fixtures as $fixture) {
                    if (!hasAllValues($fixture, _insertionMap[$configName], true)) {
                        _setupTable($fixture, $db, $tables, $test.dropTables);
                    } else {
                        $fixture.truncate($db);
                    }
                }

                foreach ($fixtures as $fixture) {
                    if (!$fixture instanceof IConstraints) {
                        continue;
                    }

                    try {
                        $fixture.createConstraints($db);
                    } catch (PDOException $e) {
                        $msg = sprintf(
                            "Unable to create constraints for fixture '%s' in '%s' test case: " ~ "\n" ~ '%s',
                            get_class($fixture),
                            get_class($test),
                            $e.getMessage()
                        );
                        throw new UIMException($msg, null, $e);
                    }
                }
            };
            _runOperation($fixtures, $createTables);

            // Use a separate transaction because of postgres.
            $insert = void (IConnection $db, array $fixtures) use ($test) {
                foreach ($fixtures as $fixture) {
                    try {
                        $fixture.insert($db);
                    } catch (PDOException $e) {
                        $msg = sprintf(
                            "Unable to insert fixture '%s' in '%s' test case: " ~ "\n" ~ '%s',
                            get_class($fixture),
                            get_class($test),
                            $e.getMessage()
                        );
                        throw new UIMException($msg, null, $e);
                    }
                }
            };
            _runOperation($fixtures, $insert);
        } catch (PDOException $e) {
            $msg = sprintf(
                "Unable to insert fixtures for '%s' test case. %s",
                get_class($test),
                $e.getMessage()
            );
            throw new RuntimeException($msg, 0, $e);
        }
    }

    /**
     * Run a function on each connection and collection of fixtures.
     *
     * @param array<string> $fixtures A list of fixtures to operate on.
     * @param callable $operation The operation to run on each connection + fixture set.
     */
    protected void _runOperation(array $fixtures, callable $operation) {
        $dbs = _fixtureConnections($fixtures);
        foreach ($dbs as $connection: $fixtures) {
            $db = ConnectionManager::get($connection);
            $logQueries = $db.isQueryLoggingEnabled();

            if ($logQueries && !_debug) {
                $db.disableQueryLogging();
            }
            $db.transactional(void (IConnection $db) use ($fixtures, $operation) {
                $db.disableConstraints(void (IConnection $db) use ($fixtures, $operation) {
                    $operation($db, $fixtures);
                });
            });
            if ($logQueries) {
                $db.enableQueryLogging(true);
            }
        }
    }

    /**
     * Get the unique list of connections that a set of fixtures contains.
     *
     * @param array<string> $fixtures The array of fixtures a list of connections is needed from.
     * @return array An array of connection names.
     */
    protected array _fixtureConnections(array $fixtures) {
        $dbs = null;
        foreach ($fixtures as $name) {
            if (!empty(_loaded[$name])) {
                $fixture = _loaded[$name];
                $dbs[$fixture.connection()][$name] = $fixture;
            }
        }

        return $dbs;
    }

    /**
     * Truncates the fixtures tables
     *
     * @param uim.cake.TestSuite\TestCase $test The test to inspect for fixture unloading.
     */
    void unload(TestCase $test) {
        $fixtures = $test.getFixtures();
        if (!$fixtures) {
            return;
        }
        $truncate = void (IConnection $db, array $fixtures) {
            $configName = $db.configName();

            foreach ($fixtures as $fixture) {
                if (
                    this.isFixtureSetup($configName, $fixture)
                    && $fixture instanceof IConstraints
                ) {
                    $fixture.dropConstraints($db);
                }
            }
        };
        _runOperation($fixtures, $truncate);
    }

    /**
     * @param string aName Name
     * @param uim.cake.Datasource\IConnection|null $connection Connection
     * @param bool $dropTables Drop all tables prior to loading schema files
     * @return void
     * @throws \UnexpectedValueException
     */
    void loadSingle(string aName, ?IConnection $connection = null, bool $dropTables = true) {
        if (!isset(_fixtureMap[$name])) {
            throw new UnexpectedValueException(sprintf("Referenced fixture class %s not found", $name));
        }

        $fixture = _fixtureMap[$name];
        if (!$connection) {
            $connection = ConnectionManager::get($fixture.connection());
        }

        if (!this.isFixtureSetup($connection.configName(), $fixture)) {
            $sources = $connection.getSchemaCollection().listTables();
            _setupTable($fixture, $connection, $sources, $dropTables);
        }

        if (!$dropTables) {
            if ($fixture instanceof IConstraints) {
                $fixture.dropConstraints($connection);
            }
            $fixture.truncate($connection);
        }

        if ($fixture instanceof IConstraints) {
            $fixture.createConstraints($connection);
        }
        $fixture.insert($connection);
    }

    /**
     * Drop all fixture tables loaded by this class
     */
    void shutDown() {
        $shutdown = void (IConnection $db, array $fixtures) {
            $connection = $db.configName();
            /** @var uim.datasources.IFixture $fixture */
            foreach ($fixtures as $fixture) {
                if (this.isFixtureSetup($connection, $fixture)) {
                    $fixture.drop($db);
                    $index = array_search($fixture, _insertionMap[$connection], true);
                    unset(_insertionMap[$connection][$index]);
                }
            }
        };
        _runOperation(array_keys(_loaded), $shutdown);
    }

    /**
     * Check whether a fixture has been inserted in a given connection name.
     *
     * @param string $connection The connection name.
     * @param uim.cake.Datasource\IFixture $fixture The fixture to check.
     */
    bool isFixtureSetup(string $connection, IFixture $fixture) {
        return isset(_insertionMap[$connection]) && hasAllValues($fixture, _insertionMap[$connection], true);
    }
}
