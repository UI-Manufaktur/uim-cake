/*********************************************************************************************************
  Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
  License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
  Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.testsuite;

@safe:
import uim.cake;

/**
 * Helper for managing fixtures.
 */
class FixtureHelper
{
    /**
     * Finds fixtures from their TestCase names such as "core.Articles".
     *
     * @param array<string> $fixtureNames Fixture names from test case
     * @return array<uim.cake.Datasource\FixtureInterface>
     */
    function loadFixtures(array $fixtureNames): array
    {
        static $cachedFixtures = [];

        $fixtures = [];
        foreach ($fixtureNames as $fixtureName) {
            if (strpos($fixtureName, ".")) {
                [$type, $pathName] = explode(".", $fixtureName, 2);
                $path = explode("/", $pathName);
                $name = array_pop($path);
                $additionalPath = implode("\\", $path);

                if ($type == "core") {
                    $baseNamespace = "Cake";
                } elseif ($type == "app") {
                    $baseNamespace = Configure::read("App.namespace");
                } elseif ($type == "plugin") {
                    [$plugin, $name] = explode(".", $pathName);
                    $baseNamespace = str_replace("/", "\\", $plugin);
                    $additionalPath = null;
                } else {
                    $baseNamespace = "";
                    $name = $fixtureName;
                }

                if (strpos($name, "/") > 0) {
                    $name = str_replace("/", "\\", $name);
                }

                $nameSegments = [
                    $baseNamespace,
                    "Test\Fixture",
                    $additionalPath,
                    $name ~ "Fixture",
                ];
                /** @psalm-var class-string<uim.cake.Datasource\FixtureInterface> */
                $className = implode("\\", array_filter($nameSegments));
            } else {
                /** @psalm-var class-string<uim.cake.Datasource\FixtureInterface> */
                $className = $fixtureName;
            }

            if (isset($fixtures[$className])) {
                throw new UnexpectedValueException("Found duplicate fixture `$fixtureName`.");
            }

            if (!class_exists($className)) {
                throw new UnexpectedValueException("Could not find fixture `$fixtureName`.");
            }

            if (!isset($cachedFixtures[$className])) {
                $cachedFixtures[$className] = new $className();
            }

            $fixtures[$className] = $cachedFixtures[$className];
        }

        return $fixtures;
    }

    /**
     * Runs the callback once per connection.
     *
     * The callback signature:
     * ```
     * function callback(IConnection $connection, array $fixtures)
     * ```
     *
     * @param \Closure $callback Callback run per connection
     * @param array<uim.cake.Datasource\FixtureInterface> $fixtures Test fixtures
     */
    void runPerConnection(Closure $callback, array $fixtures): void
    {
        $groups = [];
        foreach ($fixtures as $fixture) {
            $groups[$fixture.connection()][] = $fixture;
        }

        foreach ($groups as $connectionName: $fixtures) {
            $callback(ConnectionManager::get($connectionName), $fixtures);
        }
    }

    /**
     * Inserts fixture data.
     *
     * @param array<uim.cake.Datasource\FixtureInterface> $fixtures Test fixtures
     * @return void
     * @internal
     */
    function insert(array $fixtures): void
    {
        this.runPerConnection(function (IConnection $connection, array $groupFixtures): void {
            if ($connection instanceof Connection) {
                $sortedFixtures = this.sortByConstraint($connection, $groupFixtures);
                if ($sortedFixtures) {
                    this.insertConnection($connection, $sortedFixtures);
                } else {
                    $helper = new ConnectionHelper();
                    $helper.runWithoutConstraints(
                        $connection,
                        function (Connection $connection) use ($groupFixtures): void {
                            this.insertConnection($connection, $groupFixtures);
                        }
                    );
                }
            } else {
                this.insertConnection($connection, $groupFixtures);
            }
        }, $fixtures);
    }

    /**
     * Inserts all fixtures for a connection and provides friendly errors for bad data.
     *
     * @param uim.cake.Datasource\IConnection $connection Fixture connection
     * @param array<uim.cake.Datasource\FixtureInterface> $fixtures Connection fixtures
     */
    protected void insertConnection(IConnection $connection, array $fixtures): void
    {
        foreach ($fixtures as $fixture) {
            try {
                $fixture.insert($connection);
            } catch (PDOException $exception) {
                $message = sprintf(
                    "Unable to insert rows for table `%s`."
                        ~ " Fixture records might have invalid data or unknown contraints.\n%s",
                    $fixture.sourceName(),
                    $exception.getMessage()
                );
                throw new CakeException($message);
            }
        }
    }

    /**
     * Truncates fixture tables.
     *
     * @param array<uim.cake.Datasource\FixtureInterface> $fixtures Test fixtures
     * @return void
     * @internal
     */
    function truncate(array $fixtures): void
    {
        this.runPerConnection(function (IConnection $connection, array $groupFixtures): void {
            if ($connection instanceof Connection) {
                $sortedFixtures = null;
                if ($connection.getDriver().supports(IDriver::FEATURE_TRUNCATE_WITH_CONSTRAINTS)) {
                    $sortedFixtures = this.sortByConstraint($connection, $groupFixtures);
                }

                if ($sortedFixtures != null) {
                    this.truncateConnection($connection, array_reverse($sortedFixtures));
                } else {
                    $helper = new ConnectionHelper();
                    $helper.runWithoutConstraints(
                        $connection,
                        function (Connection $connection) use ($groupFixtures): void {
                            this.truncateConnection($connection, $groupFixtures);
                        }
                    );
                }
            } else {
                this.truncateConnection($connection, $groupFixtures);
            }
        }, $fixtures);
    }

    /**
     * Truncates all fixtures for a connection and provides friendly errors for bad data.
     *
     * @param uim.cake.Datasource\IConnection $connection Fixture connection
     * @param array<uim.cake.Datasource\FixtureInterface> $fixtures Connection fixtures
     */
    protected void truncateConnection(IConnection $connection, array $fixtures): void
    {
        foreach ($fixtures as $fixture) {
            try {
                $fixture.truncate($connection);
            } catch (PDOException $exception) {
                $message = sprintf(
                    "Unable to truncate table `%s`."
                        ~ " Fixture records might have invalid data or unknown contraints.\n%s",
                    $fixture.sourceName(),
                    $exception.getMessage()
                );
                throw new CakeException($message);
            }
        }
    }

    /**
     * Sort fixtures with foreign constraints last if possible, otherwise returns null.
     *
     * @param uim.cake.databases.Connection $connection Database connection
     * @param array<uim.cake.Datasource\FixtureInterface> $fixtures Database fixtures
     * @return array|null
     */
    protected function sortByConstraint(Connection $connection, array $fixtures): ?array
    {
        $constrained = [];
        $unconstrained = [];
        foreach ($fixtures as $fixture) {
            $references = this.getForeignReferences($connection, $fixture);
            if ($references) {
                $constrained[$fixture.sourceName()] = ["references": $references, "fixture": $fixture];
            } else {
                $unconstrained[] = $fixture;
            }
        }

        // Check if any fixtures reference another fixture with constrants
        // If they do, then there might be cross-dependencies which we don"t support sorting
        foreach ($constrained as ["references": $references]) {
            foreach ($references as $reference) {
                if (isset($constrained[$reference])) {
                    return null;
                }
            }
        }

        return array_merge($unconstrained, array_column($constrained, "fixture"));
    }

    /**
     * Gets array of foreign references for fixtures table.
     *
     * @param uim.cake.databases.Connection $connection Database connection
     * @param uim.cake.Datasource\FixtureInterface $fixture Database fixture
     * @return array<string>
     */
    protected function getForeignReferences(Connection $connection, FixtureInterface $fixture): array
    {
        static $schemas = [];

        // Get and cache off the schema since TestFixture generates a fake schema based on $fields
        $tableName = $fixture.sourceName();
        if (!isset($schemas[$tableName])) {
            $schemas[$tableName] = $connection.getSchemaCollection().describe($tableName);
        }
        $schema = $schemas[$tableName];

        $references = [];
        foreach ($schema.constraints() as $constraintName) {
            $constraint = $schema.getConstraint($constraintName);

            if ($constraint && $constraint["type"] == TableSchema::CONSTRAINT_FOREIGN) {
                $references[] = $constraint["references"][0];
            }
        }

        return $references;
    }
}
