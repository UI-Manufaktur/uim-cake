


 *


 * @since         3.0
  */module uim.cake.views;

/**
 * A view class that is used for AJAX responses.
 * Currently, only switches the default layout and sets the response type - which just maps to
 * text/html by default.
 */
class AjaxView : View {
    protected $layout = "ajax";

    // Get content type for this view.
    static string contentType() {
        return "text/html";
    }
}
