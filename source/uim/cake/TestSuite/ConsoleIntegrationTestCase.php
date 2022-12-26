

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         3.5.0
 * @license       https://www.opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.TestSuite;

import uim.cake.consoles.TestSuite\ConsoleIntegrationTestTrait;

/**
 * A test case class intended to make integration tests of cake console commands
 * easier.
 *
 * @deprecated 3.7.0 Will be removed in 5.0.0. Use {@link \Cake\TestSuite\ConsoleIntegrationTestTrait} instead
 */
abstract class ConsoleIntegrationTestCase : TestCase
{
    use ConsoleIntegrationTestTrait;
}
