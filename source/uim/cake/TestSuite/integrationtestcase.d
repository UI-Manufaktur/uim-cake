


  */module uim.cake.TestSuite;

/**
 * A test case class intended to make integration tests of
 * your controllers easier.
 *
 * This test class provides a number of helper methods and features
 * that make dispatching requests and checking their responses simpler.
 * It favours full integration tests over mock objects as you can test
 * more of your code easily and avoid some of the maintenance pitfalls
 * that mock objects create.
 *
 * @deprecated 3.7.0 Will be removed in 5.0.0. Use {@link uim.cake.TestSuite\IntegrationTestTrait} instead.
 */
abstract class IntegrationTestCase : TestCase
{
    use IntegrationTestTrait;

    /**
     * No-op method.
     *
     * @param bool $enable Unused.
     */
    void useHttpServer(bool $enable): void
    {
    }
}
