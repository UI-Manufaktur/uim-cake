/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.controllers.error;

@safe:
import uim.cake;

/**
 * Error Handling Controller
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
     * @param uim.cake.events.IEvent $event Event.
     * @return uim.cake.http.Response|null|void
     */
    function beforeRender(IEvent $event) {
        $builder = this.viewBuilder();
        $templatePath = "Error";

        if (
            this.request.getParam("prefix") &&
            in_array($builder.getTemplate(), ["error400", "error500"], true)
        ) {
            $parts = explode(DIRECTORY_SEPARATOR, (string)$builder.getTemplatePath(), -1);
            $templatePath = implode(DIRECTORY_SEPARATOR, $parts) . DIRECTORY_SEPARATOR ~ "Error";
        }

        $builder.setTemplatePath($templatePath);
    }
}
