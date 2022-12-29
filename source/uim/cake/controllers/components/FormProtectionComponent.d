module uim.cake.controllerss.components;

import uim.cake.controllerss.components;
import uim.cake.core.Configure;
import uim.cakeents\IEvent;
import uim.cakerm\FormProtector;
import uim.caketps\exceptions.BadRequestException;
import uim.caketps\Response;
import uim.cake.routings\Router;
use Closure;

/**
 * Protects against form tampering. It ensures that:
 *
 * - Form"s action (URL) is not modified.
 * - Unknown / extra fields are not added to the form.
 * - Existing fields have not been removed from the form.
 * - Values of hidden inputs have not been changed.
 *
 * @psalm-property array{validate:bool, unlockedFields:array, unlockedActions:array, validationFailureCallback:?\Closure} $_config
 */
class FormProtectionComponent : Component
{
    /**
     * Default message used for exceptions thrown.
     */
    const string DEFAULT_EXCEPTION_MESSAGE = "Form tampering protection token validation failed.";

    /**
     * Default config
     *
     * - `validate` - Whether to validate request body / data. Set to false to disable
     *   for data coming from 3rd party services, etc.
     * - `unlockedFields` - Form fields to exclude from validation. Fields can
     *   be unlocked either in the Component, or with FormHelper::unlockField().
     *   Fields that have been unlocked are not required to be part of the POST
     *   and hidden unlocked fields do not have their values checked.
     * - `unlockedActions` - Actions to exclude from POST validation checks.
     * - `validationFailureCallback` - Callback to call in case of validation
     *   failure. Must be a valid Closure. Unset by default in which case
     *   exception is thrown on validation failure.
     *
     * @var array<string, mixed>
     */
    protected STRINGAA _defaultConfig = [
        "validate":true,
        "unlockedFields":[],
        "unlockedActions":[],
        "validationFailureCallback":null,
    ];

    /**
     * Component startup.
     *
     * Token check happens here.
     *
     * @param uim.cake.events.IEvent myEvent An Event instance
     * @return uim.cake.http.Response|null
     */
    function startup(IEvent myEvent): ?Response
    {
        myRequest = this.getController().getRequest();
        myData = myRequest.getParsedBody();
        $hasData = (myData || myRequest.is(["put", "post", "delete", "patch"]));

        if (
            !in_array(myRequest.getParam("action"), _config["unlockedActions"], true)
            && $hasData
            && _config["validate"]
        ) {
            $session = myRequest.getSession();
            $session.start();
            myUrl = Router::url(myRequest.getRequestTarget());

            $formProtector = new FormProtector(_config);
            $isValid = $formProtector.validate(myData, myUrl, $session.id());

            if (!$isValid) {
                return this.validationFailure($formProtector);
            }
        }

        $token = [
            "unlockedFields":_config["unlockedFields"],
        ];
        myRequest = myRequest.withAttribute("formTokenData", [
            "unlockedFields":$token["unlockedFields"],
        ]);

        if (is_array(myData)) {
            unset(myData["_Token"]);
            myRequest = myRequest.withParsedBody(myData);
        }

        this.getController().setRequest(myRequest);

        return null;
    }

    /**
     * Events supported by this component.
     *
     * @return array<string, mixed>
     */
    array implementedEvents() {
        return [
            "Controller.startup":"startup",
        ];
    }

    /**
     * Throws a 400 - Bad request exception or calls custom callback.
     *
     * If `validationFailureCallback` config is specified, it will use this
     * callback by executing the method passing the argument as exception.
     *
     * @param uim.cake.Form\FormProtector $formProtector Form Protector instance.
     * @return uim.cake.http.Response|null If specified, validationFailureCallback"s response, or no return otherwise.
     * @throws uim.cake.http.exceptions.BadRequestException
     */
    protected auto validationFailure(FormProtector $formProtector): ?Response
    {
        if (Configure::read("debug")) {
            myException = new BadRequestException($formProtector.getError());
        } else {
            myException = new BadRequestException(static::DEFAULT_EXCEPTION_MESSAGE);
        }

        if (_config["validationFailureCallback"]) {
            return this.executeCallback(_config["validationFailureCallback"], myException);
        }

        throw myException;
    }

    /**
     * Execute callback.
     *
     * @param \Closure $callback A valid callable
     * @param uim.cake.http.exceptions.BadRequestException myException Exception instance.
     * @return uim.cake.http.Response|null
     */
    protected auto executeCallback(Closure $callback, BadRequestException myException): ?Response {
        return $callback(myException);
    }
}
