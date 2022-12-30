module uim.cake.TestSuite;

import uim.cake.consoles.TestSuite\ConsoleIntegrationTestTrait;

/**
 * A test case class intended to make integration tests of cake console commands
 * easier.
 *
 * @deprecated 3.7.0 Will be removed in 5.0.0. Use {@link uim.cake.TestSuite\ConsoleIntegrationTestTrait} instead
 */
abstract class ConsoleIntegrationTestCase : TestCase
{
    use ConsoleIntegrationTestTrait;
}
