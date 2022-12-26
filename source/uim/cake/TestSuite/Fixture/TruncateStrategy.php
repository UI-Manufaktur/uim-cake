


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         4.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.TestSuite\Fixture;

/**
 * Fixture strategy that truncates all fixture ables at the end of test.
 */
class TruncateStrategy : FixtureStrategyInterface
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
        this.helper.insert(this.fixtures);
    }

    /**
     * @inheritDoc
     */
    function teardownTest(): void
    {
        this.helper.truncate(this.fixtures);
    }
}
