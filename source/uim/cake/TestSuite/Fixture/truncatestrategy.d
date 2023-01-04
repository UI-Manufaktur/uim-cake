


 *


 * @since         4.3.0
  */module uim.cake.TestSuite\Fixture;

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
     * @var array<uim.cake.Datasource\IFixture>
     */
    protected $fixtures = [];

    /**
     * Initialize strategy.
     */
    this() {
        this.helper = new FixtureHelper();
    }


    void setupTest(array $fixtureNames)
    {
        if (empty($fixtureNames)) {
            return;
        }

        this.fixtures = this.helper.loadFixtures($fixtureNames);
        this.helper.insert(this.fixtures);
    }


    void teardownTest()
    {
        this.helper.truncate(this.fixtures);
    }
}
