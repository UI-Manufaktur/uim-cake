module uim.cake.views;

@safe:
import uim.cake;

/**
 * A view class that is used for AJAX responses.
 * Currently, only switches the default layout and sets the response type - which just maps to
 * text/html by default.
 */
class AjaxView : View {

    protected layout = "ajax";

    void initialize() {
        super.initialize();
        this.setResponse(this.getResponse().withType("ajax"));
    }
}
