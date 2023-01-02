module uim.cake.controllers.Component;

import uim.cake.controllers.Component;
import uim.cake.events.EventInterface;

/**
 * Use HTTP caching headers to see if rendering can be skipped.
 *
 * Checks if the response can be considered different according to the request
 * headers, and caching headers in the response. If the response was not modified,
 * then the controller and view render process is skipped. And the client will get a
 * response with an empty body and a "304 Not Modified" header.
 *
 * To use this component your controller actions must set either the `Last-Modified`
 * or `Etag` header. Without one of these headers being set this component
 * will have no effect.
 */
class CheckHttpCacheComponent : Component
{
    /**
     * Before Render hook
     *
     * @param uim.cake.events.IEvent $event The Controller.beforeRender event.
     */
    void beforeRender(IEvent $event) {
        $controller = this.getController();
        $response = $controller.getResponse();
        $request = $controller.getRequest();
        if (!$response.isNotModified($request)) {
            return;
        }

        $controller.setResponse($response.withNotModified());
        $event.stopPropagation();
    }
}
