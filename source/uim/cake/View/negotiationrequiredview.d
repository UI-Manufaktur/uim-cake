


 *


 * @since         4.4.0
  */module uim.cake.View;

/**
 * A view class that responds to any content-type and can be used to create
 * an empty body 406 status code response.
 *
 * This is most useful when using content-type negotiation via `viewClasses()`
 * in your controller. Add this View at the end of the acceptable View classes
 * to require clients to pick an available content-type and that you have no
 * default type.
 */
class NegotiationRequiredView : View
{
    /**
     * Get the content-type
     *
     */
    static string contentType() {
        return static::TYPE_MATCH_ALL;
    }

    /**
     * Initialization hook method.
     */
    void initialize(): void
    {
        $response = this.getResponse().withStatus(406);
        this.setResponse($response);
    }

    /**
     * Renders view with no body and a 406 status code.
     *
     * @param string|null $template Name of template file to use
     * @param string|false|null $layout Layout to use. False to disable.
     * @return string Rendered content.
     */
    string render(?string $template = null, $layout = null) {
        return "";
    }
}
