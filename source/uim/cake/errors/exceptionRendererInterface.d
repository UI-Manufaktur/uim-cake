module uim.cakerors;

use Psr\Http\Message\IResponse;

/**
 * Interface ExceptionRendererInterface
 */
interface ExceptionRendererInterface
{
    /**
     * Renders the response for the exception.
     *
     * @return \Cake\Http\Response The response to be sent.
     */
    function render(): IResponse;
}
