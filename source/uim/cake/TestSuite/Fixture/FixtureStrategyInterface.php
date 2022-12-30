


 *


 * @since         4.3.0
  */
module uim.cake.TestSuite\Fixture;

/**
 * Base interface for strategies used to manage fixtures for TestCase.
 */
interface FixtureStrategyInterface
{
    /**
     * Called before each test run in each TestCase.
     *
     * @param array<string> $fixtureNames Name of fixtures used by test.
     */
    void setupTest(array $fixtureNames): void;

    /**
     * Called after each test run in each TestCase.
     */
    void teardownTest(): void;
}
