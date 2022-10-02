

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         4.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.TestSuite\Fixture;

/**
 * Base interface for strategies used to manage fixtures for TestCase.
 */
interface FixtureStrategyInterface
{
    /**
     * Called before each test run in each TestCase.
     *
     * @param array<string> $fixtureNames Name of fixtures used by test.
     * @return void
     */
    auto setupTest(array $fixtureNames): void;

    /**
     * Called after each test run in each TestCase.
     *
     * @return void
     */
    function teardownTest(): void;
}
