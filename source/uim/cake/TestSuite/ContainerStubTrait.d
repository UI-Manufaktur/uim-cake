

/**
 * CakePHP(tm) : Rapid Development Framework (http://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (http://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (http://cakefoundation.org)
 * @since         4.2.0
 * @license       http://www.opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.TestSuite;

import uim.cake.core.Configure;
import uim.cake.core.IContainer;
import uim.cake.Event\IEvent;
use Closure;
use LogicException;

/**
 * A set of methods used for defining container services
 * in test cases.
 *
 * This trait leverages the `Application.buildContainer` event
 * to inject the mocked services into the container that the
 * application uses.
 */
trait ContainerStubTrait
{
    /**
     * The customized application class name.
     *
     * @psalm-var class-string<\Cake\Core\HttpApplicationInterface>|class-string<\Cake\Core\ConsoleApplicationInterface>|null
     * @var string|null
     */
    protected $_appClass;

    /**
     * The customized application constructor arguments.
     *
     * @var array|null
     */
    protected $_appArgs;

    /**
     * The collection of container services.
     *
     * @var array
     */
    private myContainerServices = [];

    /**
     * Configure the application class to use in integration tests.
     *
     * @param string myClass The application class name.
     * @param array|null $constructorArgs The constructor arguments for your application class.
     * @return void
     * @psalm-param class-string<\Cake\Core\HttpApplicationInterface>|class-string<\Cake\Core\ConsoleApplicationInterface> myClass
     */
    function configApplication(string myClass, ?array $constructorArgs): void
    {
        this._appClass = myClass;
        this._appArgs = $constructorArgs;
    }

    /**
     * Create an application instance.
     *
     * Uses the configuration set in `configApplication()`.
     *
     * @return \Cake\Core\HttpApplicationInterface|\Cake\Core\ConsoleApplicationInterface
     */
    protected auto createApp() {
        if (this._appClass) {
            $appClass = this._appClass;
        } else {
            /** @psalm-var class-string<\Cake\Http\BaseApplication> */
            $appClass = Configure::read('App.module') . '\Application';
        }
        if (!class_exists($appClass)) {
            throw new LogicException("Cannot load `{$appClass}` for use in integration testing.");
        }
        $appArgs = this._appArgs ?: [CONFIG];

        $app = new $appClass(...$appArgs);
        if (!empty(this.containerServices) && method_exists($app, 'getEventManager')) {
            $app.getEventManager().on('Application.buildContainer', [this, 'modifyContainer']);
        }

        return $app;
    }

    /**
     * Add a mocked service to the container.
     *
     * When the container is created the provided classname
     * will be mapped to the factory function. The factory
     * function will be used to create mocked services.
     *
     * @param string myClass The class or interface you want to define.
     * @param \Closure $factory The factory function for mocked services.
     * @return this
     */
    function mockService(string myClass, Closure $factory)
    {
        this.containerServices[myClass] = $factory;

        return this;
    }

    /**
     * Remove a mocked service to the container.
     *
     * @param string myClass The class or interface you want to remove.
     * @return this
     */
    function removeMockService(string myClass)
    {
        unset(this.containerServices[myClass]);

        return this;
    }

    /**
     * Wrap the application's container with one containing mocks.
     *
     * If any mocked services are defined, the application's container
     * will be replaced with one containing mocks. The original
     * container will be set as a delegate to the mock container.
     *
     * @param \Cake\Event\IEvent myEvent The event
     * @param \Cake\Core\IContainer myContainer The container to wrap.
     * @return \Cake\Core\IContainer|null
     */
    function modifyContainer(IEvent myEvent, IContainer myContainer): ?IContainer
    {
        if (empty(this.containerServices)) {
            return null;
        }
        foreach (this.containerServices as myKey => $factory) {
            if (myContainer.has(myKey)) {
                myContainer.extend(myKey).setConcrete($factory);
            } else {
                myContainer.add(myKey, $factory);
            }
        }

        return myContainer;
    }

    /**
     * Clears any mocks that were defined and cleans
     * up application class configuration.
     *
     * @after
     * @return void
     */
    function cleanupContainer(): void
    {
        this._appArgs = null;
        this._appClass = null;
        this.containerServices = [];
    }
}
