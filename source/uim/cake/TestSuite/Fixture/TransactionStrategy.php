

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         4.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.TestSuite\Fixture;

import uim.cake.database.Connection;
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
    this() {
        this.helper = new FixtureHelper();
    }


    auto setupTest(array $fixtureNames): void
    {
        if (empty($fixtureNames)) {
            return;
        }

        this.fixtures = this.helper.loadFixtures($fixtureNames);

        this.helper.runPerConnection(function (myConnection) {
            if (myConnection instanceof Connection) {
                assert(
                    myConnection.inTransaction() === false,
                    'Cannot start transaction strategy inside a transaction. ' .
                    'Ensure you have closed all open transactions.'
                );
                myConnection.enableSavePoints();
                if (!myConnection.isSavePointsEnabled()) {
                    throw new RuntimeException(
                        "Could not enable save points for the `{myConnection.configName()}` connection. " .
                            'Your database needs to support savepoints in order to use ' .
                            'TransactionStrategy.'
                    );
                }

                myConnection.begin();
                myConnection.createSavePoint('__fixtures__');
            }
        }, this.fixtures);

        this.helper.insert(this.fixtures);
    }


    function teardownTest(): void
    {
        this.helper.runPerConnection(function (myConnection) {
            if (myConnection.inTransaction()) {
                myConnection.rollback(true);
            }
        }, this.fixtures);
    }
}
