

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         4.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
namespace Cake\TestSuite\Fixture;

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
    function setupTest(array $fixtureNames): void;

    /**
     * Called after each test run in each TestCase.
     *
     * @return void
     */
    function teardownTest(): void;
}
