


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         4.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.TestSuite\Fixture;

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
     * @var \Cake\TestSuite\Fixture\FixtureHelper
     */
    protected $helper;

    /**
     * @var array<\Cake\Datasource\FixtureInterface>
     */
    protected $fixtures = [];

    /**
     * Initialize strategy.
     */
    public this() {
        this.helper = new FixtureHelper();
    }

    /**
     * @inheritDoc
     */
    function setupTest(array $fixtureNames): void
    {
        if (empty($fixtureNames)) {
            return;
        }

        this.fixtures = this.helper.loadFixtures($fixtureNames);

        this.helper.runPerConnection(function ($connection) {
            if ($connection instanceof Connection) {
                assert(
                    $connection.inTransaction() == false,
                    "Cannot start transaction strategy inside a transaction. " .
                    "Ensure you have closed all open transactions."
                );
                $connection.enableSavePoints();
                if (!$connection.isSavePointsEnabled()) {
                    throw new RuntimeException(
                        "Could not enable save points for the `{$connection.configName()}` connection. " .
                            "Your database needs to support savepoints in order to use " .
                            "TransactionStrategy."
                    );
                }

                $connection.begin();
                $connection.createSavePoint("__fixtures__");
            }
        }, this.fixtures);

        this.helper.insert(this.fixtures);
    }

    /**
     * @inheritDoc
     */
    function teardownTest(): void
    {
        this.helper.runPerConnection(function ($connection) {
            if ($connection.inTransaction()) {
                $connection.rollback(true);
            }
        }, this.fixtures);
    }
}
