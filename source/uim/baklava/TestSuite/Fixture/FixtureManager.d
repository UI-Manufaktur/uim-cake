module uim.baklava.TestSuite\Fixture;

import uim.baklava.core.Configure;
import uim.baklava.core.Exception\CakeException;
import uim.baklava.databases.ConstraintsInterface;
import uim.baklava.databases.Driver\Postgres;
import uim.baklava.databases.Schema\TableSchema;
import uim.baklava.databases.Schema\TableSchemaAwareInterface;
import uim.baklava.Datasource\ConnectionInterface;
import uim.baklava.Datasource\ConnectionManager;
import uim.baklava.Datasource\FixtureInterface;
import uim.baklava.TestSuite\TestCase;
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
     *
     * @var bool
     */
    protected $_initialized = false;

    /**
     * Holds the fixture classes that where instantiated
     *
     * @var array<\Cake\Datasource\FixtureInterface>
     */
    protected $_loaded = [];

    /**
     * Holds the fixture classes that where instantiated indexed by class name
     *
     * @var array<\Cake\Datasource\FixtureInterface>
     */
    protected $_fixtureMap = [];

    /**
     * A map of connection names and the fixture currently in it.
     *
     * @var array<string, array<\Cake\Datasource\FixtureInterface>>
     */
    protected $_insertionMap = [];

    /**
     * List of TestCase class name that have been processed
     *
     * @var array<string, bool>
     */
    protected $_processed = [];

    /**
     * Is the test runner being run with `--debug` enabled.
     * When true, fixture SQL will also be logged.
     *
     * @var bool
     */
    protected $_debug = false;

    /**
     * Modify the debug mode.
     *
     * @param bool $debug Whether fixture debug mode is enabled.
     * @return void
     */
    auto setDebug(bool $debug): void
    {
        this._debug = $debug;
    }

    /**
     * @param \Cake\TestSuite\TestCase $test Test case
     * @return void
     */
    function fixturize(TestCase $test): void
    {
        this._initDb();
        if (!$test.getFixtures() || !empty(this._processed[get_class($test)])) {
            return;
        }
        this._loadFixtures($test);
        this._processed[get_class($test)] = true;
    }

    /**
     * @return \Cake\Datasource\FixtureInterface[]
     */
    function loaded(): array
    {
        return this._loaded;
    }

    /**
     * @return array<string>
     */
    auto getInserted(): array
    {
        $inserted = [];
        foreach (this._insertionMap as $fixtures) {
            foreach ($fixtures as $fixture) {
                /** @var \Cake\TestSuite\Fixture\TestFixture $fixture */
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
     *
     * @return void
     */
    protected auto _aliasConnections(): void
    {
        myConnections = ConnectionManager::configured();
        ConnectionManager::alias('test', 'default');
        $map = [];
        foreach (myConnections as myConnection) {
            if (myConnection === 'test' || myConnection === 'default') {
                continue;
            }
            if (isset($map[myConnection])) {
                continue;
            }
            if (strpos(myConnection, 'test_') === 0) {
                $map[myConnection] = substr(myConnection, 5);
            } else {
                $map['test_' . myConnection] = myConnection;
            }
        }
        foreach ($map as $testConnection => $normal) {
            ConnectionManager::alias($testConnection, $normal);
        }
    }

    /**
     * Initializes this class with a DataSource object to use as default for all fixtures
     *
     * @return void
     */
    protected auto _initDb(): void
    {
        if (this._initialized) {
            return;
        }
        this._aliasConnections();
        this._initialized = true;
    }

    /**
     * Looks for fixture files and instantiates the classes accordingly
     *
     * @param \Cake\TestSuite\TestCase $test The test suite to load fixtures for.
     * @return void
     * @throws \UnexpectedValueException when a referenced fixture does not exist.
     */
    protected auto _loadFixtures(TestCase $test): void
    {
        $fixtures = $test.getFixtures();
        if (!$fixtures) {
            return;
        }
        foreach ($fixtures as $fixture) {
            if (isset(this._loaded[$fixture])) {
                continue;
            }

            if (strpos($fixture, '.')) {
                [myType, myPathName] = explode('.', $fixture, 2);
                myPath = explode('/', myPathName);
                myName = array_pop(myPath);
                $additionalPath = implode('\\', myPath);

                if (myType === 'core') {
                    $basemodule = 'Cake';
                } elseif (myType === 'app') {
                    $basemodule = Configure::read('App.module');
                } elseif (myType === 'plugin') {
                    [myPlugin, myName] = explode('.', myPathName);
                    $basemodule = str_replace('/', '\\', myPlugin);
                    $additionalPath = null;
                } else {
                    $basemodule = '';
                    myName = $fixture;
                }

                if (strpos(myName, '/') > 0) {
                    myName = str_replace('/', '\\', myName);
                }

                myNamesegments = [
                    $basemodule,
                    'Test\Fixture',
                    $additionalPath,
                    myName . 'Fixture',
                ];
                /** @psalm-var class-string<\Cake\Datasource\FixtureInterface> */
                myClassName = implode('\\', array_filter(myNamesegments));
            } else {
                /** @psalm-var class-string<\Cake\Datasource\FixtureInterface> */
                myClassName = $fixture;
                /** @psalm-suppress PossiblyFalseArgument */
                myName = preg_replace('/Fixture\z/', '', substr(strrchr($fixture, '\\'), 1));
            }

            if (class_exists(myClassName)) {
                this._loaded[$fixture] = new myClassName();
                this._fixtureMap[myName] = this._loaded[$fixture];
            } else {
                $msg = sprintf(
                    'Referenced fixture class "%s" not found. Fixture "%s" was referenced in test case "%s".',
                    myClassName,
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
     * @param \Cake\Datasource\FixtureInterface $fixture the fixture object to create
     * @param \Cake\Datasource\ConnectionInterface $db The Connection object instance to use
     * @param array<string> $sources The existing tables in the datasource.
     * @param bool $drop whether drop the fixture if it is already created or not
     * @return void
     */
    protected auto _setupTable(
        FixtureInterface $fixture,
        ConnectionInterface $db,
        array $sources,
        bool $drop = true
    ): void {
        myConfigName = $db.configName();
        $isFixtureSetup = this.isFixtureSetup(myConfigName, $fixture);
        if ($isFixtureSetup) {
            return;
        }

        myTable = $fixture.sourceName();
        $exists = in_array(myTable, $sources, true);

        $hasSchema = $fixture instanceof TableSchemaAwareInterface && $fixture.getTableSchema() instanceof TableSchema;

        if (($drop && $exists) || ($exists && $hasSchema)) {
            $fixture.drop($db);
            $fixture.create($db);
        } elseif (!$exists) {
            $fixture.create($db);
        } else {
            $fixture.truncate($db);
        }

        this._insertionMap[myConfigName][] = $fixture;
    }

    /**
     * @param \Cake\TestSuite\TestCase $test Test case
     * @return void
     * @throws \RuntimeException
     */
    function load(TestCase $test): void
    {
        $fixtures = $test.getFixtures();
        if (!$fixtures || !$test.autoFixtures) {
            return;
        }

        try {
            $createTables = function (ConnectionInterface $db, array $fixtures) use ($test): void {
                /** @var array<\Cake\Datasource\FixtureInterface> $fixtures */
                myTables = $db.getSchemaCollection().listTables();
                myConfigName = $db.configName();
                this._insertionMap[myConfigName] = this._insertionMap[myConfigName] ?? [];

                foreach ($fixtures as $fixture) {
                    if (!$fixture instanceof ConstraintsInterface) {
                        continue;
                    }

                    if (in_array($fixture.sourceName(), myTables, true)) {
                        try {
                            $fixture.dropConstraints($db);
                        } catch (PDOException $e) {
                            $msg = sprintf(
                                'Unable to drop constraints for fixture "%s" in "%s" test case: ' . "\n" . '%s',
                                get_class($fixture),
                                get_class($test),
                                $e.getMessage()
                            );
                            throw new CakeException($msg, null, $e);
                        }
                    }
                }

                foreach ($fixtures as $fixture) {
                    if (!in_array($fixture, this._insertionMap[myConfigName], true)) {
                        this._setupTable($fixture, $db, myTables, $test.dropTables);
                    } else {
                        $fixture.truncate($db);
                    }
                }

                foreach ($fixtures as $fixture) {
                    if (!$fixture instanceof ConstraintsInterface) {
                        continue;
                    }

                    try {
                        $fixture.createConstraints($db);
                    } catch (PDOException $e) {
                        $msg = sprintf(
                            'Unable to create constraints for fixture "%s" in "%s" test case: ' . "\n" . '%s',
                            get_class($fixture),
                            get_class($test),
                            $e.getMessage()
                        );
                        throw new CakeException($msg, null, $e);
                    }
                }
            };
            this._runOperation($fixtures, $createTables);

            // Use a separate transaction because of postgres.
            $insert = function (ConnectionInterface $db, array $fixtures) use ($test): void {
                foreach ($fixtures as $fixture) {
                    try {
                        $fixture.insert($db);
                    } catch (PDOException $e) {
                        $msg = sprintf(
                            'Unable to insert fixture "%s" in "%s" test case: ' . "\n" . '%s',
                            get_class($fixture),
                            get_class($test),
                            $e.getMessage()
                        );
                        throw new CakeException($msg, null, $e);
                    }
                }
            };
            this._runOperation($fixtures, $insert);
        } catch (PDOException $e) {
            $msg = sprintf(
                'Unable to insert fixtures for "%s" test case. %s',
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
     * @return void
     */
    protected auto _runOperation(array $fixtures, callable $operation): void
    {
        $dbs = this._fixtureConnections($fixtures);
        foreach ($dbs as myConnection => $fixtures) {
            $db = ConnectionManager::get(myConnection);
            $logQueries = $db.isQueryLoggingEnabled();

            if ($logQueries && !this._debug) {
                $db.disableQueryLogging();
            }
            if ($db.getDriver() instanceof Postgres) {
                // disabling foreign key constraints is only valid in a transaction
                $db.transactional(function (ConnectionInterface $db) use ($fixtures, $operation): void {
                    $db.disableConstraints(function (ConnectionInterface $db) use ($fixtures, $operation): void {
                        $operation($db, $fixtures);
                    });
                });
            } else {
                $db.disableConstraints(function (ConnectionInterface $db) use ($fixtures, $operation): void {
                    $operation($db, $fixtures);
                });
            }
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
    protected auto _fixtureConnections(array $fixtures): array
    {
        $dbs = [];
        foreach ($fixtures as myName) {
            if (!empty(this._loaded[myName])) {
                $fixture = this._loaded[myName];
                $dbs[$fixture.connection()][myName] = $fixture;
            }
        }

        return $dbs;
    }

    /**
     * Truncates the fixtures tables
     *
     * @param \Cake\TestSuite\TestCase $test The test to inspect for fixture unloading.
     * @return void
     */
    function unload(TestCase $test): void
    {
        $fixtures = $test.getFixtures();
        if (!$fixtures) {
            return;
        }
        $truncate = function (ConnectionInterface $db, array $fixtures): void {
            myConfigName = $db.configName();

            foreach ($fixtures as $fixture) {
                if (
                    this.isFixtureSetup(myConfigName, $fixture)
                    && $fixture instanceof ConstraintsInterface
                ) {
                    $fixture.dropConstraints($db);
                }
            }
        };
        this._runOperation($fixtures, $truncate);
    }

    /**
     * @param string myName Name
     * @param \Cake\Datasource\ConnectionInterface|null myConnection Connection
     * @param bool $dropTables Drop all tables prior to loading schema files
     * @return void
     * @throws \UnexpectedValueException
     */
    function loadSingle(string myName, ?ConnectionInterface myConnection = null, bool $dropTables = true): void
    {
        if (!isset(this._fixtureMap[myName])) {
            throw new UnexpectedValueException(sprintf('Referenced fixture class %s not found', myName));
        }

        $fixture = this._fixtureMap[myName];
        if (!myConnection) {
            myConnection = ConnectionManager::get($fixture.connection());
        }

        if (!this.isFixtureSetup(myConnection.configName(), $fixture)) {
            $sources = myConnection.getSchemaCollection().listTables();
            this._setupTable($fixture, myConnection, $sources, $dropTables);
        }

        if (!$dropTables) {
            if ($fixture instanceof ConstraintsInterface) {
                $fixture.dropConstraints(myConnection);
            }
            $fixture.truncate(myConnection);
        }

        if ($fixture instanceof ConstraintsInterface) {
            $fixture.createConstraints(myConnection);
        }
        $fixture.insert(myConnection);
    }

    /**
     * Drop all fixture tables loaded by this class
     *
     * @return void
     */
    function shutDown(): void
    {
        $shutdown = function (ConnectionInterface $db, array $fixtures): void {
            myConnection = $db.configName();
            /** @var \Cake\Datasource\FixtureInterface $fixture */
            foreach ($fixtures as $fixture) {
                if (this.isFixtureSetup(myConnection, $fixture)) {
                    $fixture.drop($db);
                    $index = array_search($fixture, this._insertionMap[myConnection], true);
                    unset(this._insertionMap[myConnection][$index]);
                }
            }
        };
        this._runOperation(array_keys(this._loaded), $shutdown);
    }

    /**
     * Check whether a fixture has been inserted in a given connection name.
     *
     * @param string myConnection The connection name.
     * @param \Cake\Datasource\FixtureInterface $fixture The fixture to check.
     * @return bool
     */
    function isFixtureSetup(string myConnection, FixtureInterface $fixture): bool
    {
        return isset(this._insertionMap[myConnection]) && in_array($fixture, this._insertionMap[myConnection], true);
    }
}
