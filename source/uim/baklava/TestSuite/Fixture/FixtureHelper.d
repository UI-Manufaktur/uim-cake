

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         4.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.TestSuite\Fixture;

import uim.baklava.core.Configure;
import uim.baklava.databases.Connection;
import uim.baklava.databases.IDriver;
import uim.baklava.databases.Schema\TableSchema;
import uim.baklava.Datasource\ConnectionInterface;
import uim.baklava.Datasource\ConnectionManager;
import uim.baklava.Datasource\FixtureInterface;
import uim.baklava.TestSuite\ConnectionHelper;
use Closure;
use UnexpectedValueException;

/**
 * Helper for managing fixtures.
 */
class FixtureHelper
{
    /**
     * Finds fixtures from their TestCase names such as 'core.Articles'.
     *
     * @param array<string> $fixtureNames Fixture names from test case
     * @return array<\Cake\Datasource\FixtureInterface>
     */
    function loadFixtures(array $fixtureNames): array
    {
        static $cachedFixtures = [];

        $fixtures = [];
        foreach ($fixtureNames as $fixtureName) {
            if (strpos($fixtureName, '.')) {
                [myType, myPathName] = explode('.', $fixtureName, 2);
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
                    myName = $fixtureName;
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
                myClassName = $fixtureName;
            }

            if (isset($fixtures[myClassName])) {
                throw new UnexpectedValueException("Found duplicate fixture `$fixtureName`.");
            }

            if (!class_exists(myClassName)) {
                throw new UnexpectedValueException("Could not find fixture `$fixtureName`.");
            }

            if (!isset($cachedFixtures[myClassName])) {
                $cachedFixtures[myClassName] = new myClassName();
            }

            $fixtures[myClassName] = $cachedFixtures[myClassName];
        }

        return $fixtures;
    }

    /**
     * Runs the callback once per connection.
     *
     * The callback signature:
     * ```
     * function callback(ConnectionInterface myConnection, array $fixtures)
     * ```
     *
     * @param \Closure $callback Callback run per connection
     * @param array<\Cake\Datasource\FixtureInterface> $fixtures Test fixtures
     * @return void
     */
    function runPerConnection(Closure $callback, array $fixtures): void
    {
        $groups = [];
        foreach ($fixtures as $fixture) {
            $groups[$fixture.connection()][] = $fixture;
        }

        foreach ($groups as myConnectionName => $fixtures) {
            $callback(ConnectionManager::get(myConnectionName), $fixtures);
        }
    }

    /**
     * Inserts fixture data.
     *
     * @param array<\Cake\Datasource\FixtureInterface> $fixtures Test fixtures
     * @return void
     * @internal
     */
    function insert(array $fixtures): void
    {
        this.runPerConnection(function (ConnectionInterface myConnection, array $groupFixtures) {
            if (myConnection instanceof Connection) {
                $sortedFixtures = this.sortByConstraint(myConnection, $groupFixtures);
                if ($sortedFixtures) {
                    foreach ($sortedFixtures as $fixture) {
                        $fixture.insert(myConnection);
                    }
                } else {
                    $helper = new ConnectionHelper();
                    $helper.runWithoutConstraints(myConnection, function (Connection myConnection) use ($groupFixtures) {
                        foreach ($groupFixtures as $fixture) {
                            $fixture.insert(myConnection);
                        }
                    });
                }
            } else {
                foreach ($groupFixtures as $fixture) {
                    $fixture.insert(myConnection);
                }
            }
        }, $fixtures);
    }

    /**
     * Truncates fixture tables.
     *
     * @param array<\Cake\Datasource\FixtureInterface> $fixtures Test fixtures
     * @return void
     * @internal
     */
    function truncate(array $fixtures): void
    {
        this.runPerConnection(function (ConnectionInterface myConnection, array $groupFixtures) {
            if (myConnection instanceof Connection) {
                $sortedFixtures = null;
                if (myConnection.getDriver().supports(IDriver::FEATURE_TRUNCATE_WITH_CONSTRAINTS)) {
                    $sortedFixtures = this.sortByConstraint(myConnection, $groupFixtures);
                }

                if ($sortedFixtures !== null) {
                    foreach (array_reverse($sortedFixtures) as $fixture) {
                        $fixture.truncate(myConnection);
                    }
                } else {
                    $helper = new ConnectionHelper();
                    $helper.runWithoutConstraints(myConnection, function (Connection myConnection) use ($groupFixtures) {
                        foreach ($groupFixtures as $fixture) {
                            $fixture.truncate(myConnection);
                        }
                    });
                }
            } else {
                foreach ($groupFixtures as $fixture) {
                    $fixture.truncate(myConnection);
                }
            }
        }, $fixtures);
    }

    /**
     * Sort fixtures with foreign constraints last if possible, otherwise returns null.
     *
     * @param \Cake\Database\Connection myConnection Database connection
     * @param array<\Cake\Datasource\FixtureInterface> $fixtures Database fixtures
     * @return array|null
     */
    protected auto sortByConstraint(Connection myConnection, array $fixtures): ?array
    {
        $constrained = [];
        $unconstrained = [];
        foreach ($fixtures as $fixture) {
            $references = this.getForeignReferences(myConnection, $fixture);
            if ($references) {
                $constrained[$fixture.sourceName()] = ['references' => $references, 'fixture' => $fixture];
            } else {
                $unconstrained[] = $fixture;
            }
        }

        // Check if any fixtures reference another fixture with constrants
        // If they do, then there might be cross-dependencies which we don't support sorting
        foreach ($constrained as ['references' => $references]) {
            foreach ($references as $reference) {
                if (isset($constrained[$reference])) {
                    return null;
                }
            }
        }

        return array_merge($unconstrained, array_column($constrained, 'fixture'));
    }

    /**
     * Gets array of foreign references for fixtures table.
     *
     * @param \Cake\Database\Connection myConnection Database connection
     * @param \Cake\Datasource\FixtureInterface $fixture Database fixture
     * @return array
     */
    protected auto getForeignReferences(Connection myConnection, FixtureInterface $fixture): array
    {
        static $schemas = [];

        // Get and cache off the schema since TestFixture generates a fake schema based on myFields
        myTableName = $fixture.sourceName();
        if (!isset($schemas[myTableName])) {
            $schemas[myTableName] = myConnection.getSchemaCollection().describe(myTableName);
        }
        $schema = $schemas[myTableName];

        $references = [];
        foreach ($schema.constraints() as $constraintName) {
            $constraint = $schema.getConstraint($constraintName);

            if ($constraint && $constraint['type'] === TableSchema::CONSTRAINT_FOREIGN) {
                $references[] = $constraint['references'][0];
            }
        }

        return $references;
    }
}
