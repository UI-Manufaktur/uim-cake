module uim.cake.controllers.error;

@safe:
import uim.cake

/* import uim.cakeents\IEvent;
 */
/**
 * Error Handling Controller
 *
 * Controller used by ErrorHandler to render error views.
 */
class ErrorController : Controller {
  // Initialization hook method.
  void initialize() {
    this.loadComponent("RequestHandler");
  }

  /**
    * beforeRender callback.
    *
    * @param \Cake\Event\IEvent myEvent Event.
    * @return \Cake\Http\Response|null|void
    */
  function beforeRender(IEvent myEvent) {
    myBuilder = this.viewBuilder();
    myTemplatePath = "Error";

    if (
        this.request.getParam("prefix") &&
        in_array(myBuilder.getTemplate(), ["error400", "error500"], true)
    ) {
        $parts = explode(DIRECTORY_SEPARATOR, (string)myBuilder.getTemplatePath(), -1);
        myTemplatePath = implode(DIRECTORY_SEPARATOR, $parts) . DIRECTORY_SEPARATOR . "Error";
    }

    myBuilder.setTemplatePath(myTemplatePath);
  }
}
