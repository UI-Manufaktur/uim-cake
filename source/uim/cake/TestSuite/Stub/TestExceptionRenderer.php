


 *


 * @since         3.5.0
  */
module uim.cake.TestSuite\Stub;

import uim.cake.errors.ExceptionRendererInterface;
use LogicException;
use Psr\Http\Message\IResponse;
use Throwable;

/**
 * Test Exception Renderer.
 *
 * Use this class if you want to re-throw exceptions that would otherwise be
 * caught by the ErrorHandlerMiddleware. This is useful while debugging or
 * writing integration test cases.
 *
 * @see uim.cake.TestSuite\IntegrationTestCase::disableErrorHandlerMiddleware()
 * @internal
 */
class TestExceptionRenderer : ExceptionRendererInterface
{
    /**
     * Simply rethrow the given exception
     *
     * @param \Throwable $exception Exception.
     * @return void
     * @throws \Throwable $exception Rethrows the passed exception.
     */
    public this(Throwable $exception) {
        throw $exception;
    }


    function render(): IResponse
    {
        throw new LogicException("You cannot use this class to render exceptions.");
    }

    /**
     * Part of upcoming interface requirements
     *
     * @param \Psr\Http\Message\IResponse|string $output The output or response to send.
     * @return void
     */
    function write($output): void
    {
    }
}
