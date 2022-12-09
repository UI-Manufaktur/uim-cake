module uim.cake.errors;

@safe:
import uim.cake;

// IExceptionRenderer
interface IExceptionRenderer {
    /**
     * Renders the response for the exception.
     *
     * @return The response to be sent.
     */
    IResponse render();
}
