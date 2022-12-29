


 *


 * @since         3.0
  */
module uim.cake.View;

/**
 * A view class that is used for AJAX responses.
 * Currently, only switches the default layout and sets the response type - which just maps to
 * text/html by default.
 */
class AjaxView : View
{

    protected $layout = "ajax";

    /**
     * Get content type for this view.
     *
     * @return string
     */
    static function contentType(): string
    {
        return "text/html";
    }
}
