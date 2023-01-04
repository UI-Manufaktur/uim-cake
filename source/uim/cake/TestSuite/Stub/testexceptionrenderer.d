module uim.cake.TestSuite\Stub;

import uim.cake.errors.ExceptionRendererInterface;
use LogicException;
use Psr\Http\messages.IResponse;
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
    this(Throwable $exception) {
        throw $exception;
    }


    function render(): IResponse
    {
        throw new LogicException("You cannot use this class to render exceptions.");
    }

    /**
     * Part of upcoming interface requirements
     *
     * @param \Psr\Http\messages.IResponse|string $output The output or response to send.
     */
    void write($output)
    {
    }
}
