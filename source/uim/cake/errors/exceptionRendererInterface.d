module uim.cake.errors;

@safe:
import uim.cake;

/**
 * Interface IExceptionRenderer
 */
interface IExceptionRenderer
{
    /**
     * Renders the response for the exception.
     *
     * @return \Cake\Http\Response The response to be sent.
     */
    function render(): IResponse;
}
