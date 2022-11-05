module uim.baklava.controllers.components;

import uim.baklava.controllers.components;
import uim.baklava.core.Configure;
import uim.baklava.events\IEvent;
import uim.baklava.Form\FormProtector;
import uim.baklava.https\Exception\BadRequestException;
import uim.baklava.https\Response;
import uim.baklava.routings\Router;
use Closure;

/**
 * Protects against form tampering. It ensures that:
 *
 * - Form's action (URL) is not modified.
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
     *
     * @var string
     */
    public const DEFAULT_EXCEPTION_MESSAGE = 'Form tampering protection token validation failed.';

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
    protected $_defaultConfig = [
        'validate' => true,
        'unlockedFields' => [],
        'unlockedActions' => [],
        'validationFailureCallback' => null,
    ];

    /**
     * Component startup.
     *
     * Token check happens here.
     *
     * @param \Cake\Event\IEvent myEvent An Event instance
     * @return \Cake\Http\Response|null
     */
    function startup(IEvent myEvent): ?Response
    {
        myRequest = this.getController().getRequest();
        myData = myRequest.getParsedBody();
        $hasData = (myData || myRequest.is(['put', 'post', 'delete', 'patch']));

        if (
            !in_array(myRequest.getParam('action'), this._config['unlockedActions'], true)
            && $hasData
            && this._config['validate']
        ) {
            $session = myRequest.getSession();
            $session.start();
            myUrl = Router::url(myRequest.getRequestTarget());

            $formProtector = new FormProtector(this._config);
            $isValid = $formProtector.validate(myData, myUrl, $session.id());

            if (!$isValid) {
                return this.validationFailure($formProtector);
            }
        }

        $token = [
            'unlockedFields' => this._config['unlockedFields'],
        ];
        myRequest = myRequest.withAttribute('formTokenData', [
            'unlockedFields' => $token['unlockedFields'],
        ]);

        if (is_array(myData)) {
            unset(myData['_Token']);
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
    function implementedEvents(): array
    {
        return [
            'Controller.startup' => 'startup',
        ];
    }

    /**
     * Throws a 400 - Bad request exception or calls custom callback.
     *
     * If `validationFailureCallback` config is specified, it will use this
     * callback by executing the method passing the argument as exception.
     *
     * @param \Cake\Form\FormProtector $formProtector Form Protector instance.
     * @return \Cake\Http\Response|null If specified, validationFailureCallback's response, or no return otherwise.
     * @throws \Cake\Http\Exception\BadRequestException
     */
    protected auto validationFailure(FormProtector $formProtector): ?Response
    {
        if (Configure::read('debug')) {
            myException = new BadRequestException($formProtector.getError());
        } else {
            myException = new BadRequestException(static::DEFAULT_EXCEPTION_MESSAGE);
        }

        if (this._config['validationFailureCallback']) {
            return this.executeCallback(this._config['validationFailureCallback'], myException);
        }

        throw myException;
    }

    /**
     * Execute callback.
     *
     * @param \Closure $callback A valid callable
     * @param \Cake\Http\Exception\BadRequestException myException Exception instance.
     * @return \Cake\Http\Response|null
     */
    protected auto executeCallback(Closure $callback, BadRequestException myException): ?Response
    {
        return $callback(myException);
    }
}
