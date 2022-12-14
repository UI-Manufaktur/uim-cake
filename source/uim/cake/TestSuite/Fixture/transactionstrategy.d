


 *


 * @since         4.3.0
  */module uim.cake.TestSuite\Fixture;

import uim.cake.databases.Connection;
use RuntimeException;

/**
 * Fixture strategy that wraps fixtures in a transaction that is rolled back
 * after each test.
 *
 * Any test that calls Connection::rollback(true) will break this strategy.
 */
class TransactionStrategy : FixtureStrategyInterface
{
    /**
     * @var uim.cake.TestSuite\Fixture\FixtureHelper
     */
    protected $helper;

    /**
     * @var array<uim.cake.Datasource\IFixture>
     */
    protected $fixtures = null;

    /**
     * Initialize strategy.
     */
    this() {
        this.helper = new FixtureHelper();
    }


    void setupTest(array $fixtureNames) {
        if (empty($fixtureNames)) {
            return;
        }

        this.fixtures = this.helper.loadFixtures($fixtureNames);

        this.helper.runPerConnection(function ($connection) {
            if ($connection instanceof Connection) {
                assert(
                    $connection.inTransaction() == false,
                    "Cannot start transaction strategy inside a transaction~ " ~
                    "Ensure you have closed all open transactions."
                );
                $connection.enableSavePoints();
                if (!$connection.isSavePointsEnabled()) {
                    throw new RuntimeException(
                        "Could not enable save points for the `{$connection.configName()}` connection~ " ~
                            "Your database needs to support savepoints in order to use " ~
                            "TransactionStrategy."
                    );
                }

                $connection.begin();
                $connection.createSavePoint("__fixtures__");
            }
        }, this.fixtures);

        this.helper.insert(this.fixtures);
    }


    void teardownTest() {
        this.helper.runPerConnection(function ($connection) {
            if ($connection.inTransaction()) {
                $connection.rollback(true);
            }
        }, this.fixtures);
    }
}
