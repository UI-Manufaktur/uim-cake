

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.5.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.TestSuite\Stub;

use Throwable;

/**
 * Test Exception Renderer.
 *
 * Use this class if you want to re-throw exceptions that would otherwise be
 * caught by the ErrorHandlerMiddleware. This is useful while debugging or
 * writing integration test cases.
 *
 * @see \Cake\TestSuite\IntegrationTestCase::disableErrorHandlerMiddleware()
 * @internal
 */
class TestExceptionRenderer
{
    /**
     * Simply rethrow the given exception
     *
     * @param \Throwable myException Exception.
     * @return void
     * @throws \Throwable myException Rethrows the passed exception.
     */
    this(Throwable myException)
    {
        throw myException;
    }
}
