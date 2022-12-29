


 *


 * @since         2.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Controller;

import uim.cake.events.EventInterface;

/**
 * Error Handling Controller
 *
 * Controller used by ErrorHandler to render error views.
 */
class ErrorController : Controller
{
    /**
     * Initialization hook method.
     *
     * @return void
     */
    function initialize(): void
    {
        this.loadComponent("RequestHandler");
    }

    /**
     * beforeRender callback.
     *
     * @param \Cake\Event\IEvent $event Event.
     * @return \Cake\Http\Response|null|void
     */
    function beforeRender(IEvent $event) {
        $builder = this.viewBuilder();
        $templatePath = "Error";

        if (
            this.request.getParam("prefix") &&
            in_array($builder.getTemplate(), ["error400", "error500"], true)
        ) {
            $parts = explode(DIRECTORY_SEPARATOR, (string)$builder.getTemplatePath(), -1);
            $templatePath = implode(DIRECTORY_SEPARATOR, $parts) . DIRECTORY_SEPARATOR . "Error";
        }

        $builder.setTemplatePath($templatePath);
    }
}
