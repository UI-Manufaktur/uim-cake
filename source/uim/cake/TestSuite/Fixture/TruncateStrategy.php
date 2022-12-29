


 *


 * @since         4.3.0
  */
module uim.cake.TestSuite\Fixture;

/**
 * Fixture strategy that truncates all fixture ables at the end of test.
 */
class TruncateStrategy : FixtureStrategyInterface
{
    /**
     * @var uim.cake.TestSuite\Fixture\FixtureHelper
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


    function setupTest(array $fixtureNames): void
    {
        if (empty($fixtureNames)) {
            return;
        }

        this.fixtures = this.helper.loadFixtures($fixtureNames);
        this.helper.insert(this.fixtures);
    }


    function teardownTest(): void
    {
        this.helper.truncate(this.fixtures);
    }
}
