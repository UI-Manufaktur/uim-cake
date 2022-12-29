

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice
 *

 * @since         4.2.0
 * @license       https://www.opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.cores.TestSuite;

import uim.cake.cores.Configure;
import uim.cake.cores.IContainer;
import uim.cake.events.EventInterface;
use Closure;
use League\Container\Exception\NotFoundException;
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
     * @psalm-var class-string<\Cake\Core\IHttpApplication>|class-string<\Cake\Core\IConsoleApplication>|null
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
    private $containerServices = [];

    /**
     * Configure the application class to use in integration tests.
     *
     * @param string $class The application class name.
     * @param array|null $constructorArgs The constructor arguments for your application class.
     * @return void
     * @psalm-param class-string<\Cake\Core\IHttpApplication>|class-string<\Cake\Core\IConsoleApplication> $class
     */
    function configApplication(string $class, ?array $constructorArgs): void
    {
        _appClass = $class;
        _appArgs = $constructorArgs;
    }

    /**
     * Create an application instance.
     *
     * Uses the configuration set in `configApplication()`.
     *
     * @return uim.cake.Core\IHttpApplication|\Cake\Core\IConsoleApplication
     */
    protected function createApp() {
        if (_appClass) {
            $appClass = _appClass;
        } else {
            /** @psalm-var class-string<\Cake\Http\BaseApplication> */
            $appClass = Configure::read("App.namespace") . "\Application";
        }
        if (!class_exists($appClass)) {
            throw new LogicException("Cannot load `{$appClass}` for use in integration testing.");
        }
        $appArgs = _appArgs ?: [CONFIG];

        $app = new $appClass(...$appArgs);
        if (!empty(this.containerServices) && method_exists($app, "getEventManager")) {
            $app.getEventManager().on("Application.buildContainer", [this, "modifyContainer"]);
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
     * @param string $class The class or interface you want to define.
     * @param \Closure $factory The factory function for mocked services.
     * @return this
     */
    function mockService(string $class, Closure $factory) {
        this.containerServices[$class] = $factory;

        return this;
    }

    /**
     * Remove a mocked service to the container.
     *
     * @param string $class The class or interface you want to remove.
     * @return this
     */
    function removeMockService(string $class) {
        unset(this.containerServices[$class]);

        return this;
    }

    /**
     * Wrap the application"s container with one containing mocks.
     *
     * If any mocked services are defined, the application"s container
     * will be replaced with one containing mocks. The original
     * container will be set as a delegate to the mock container.
     *
     * @param uim.cake.Event\IEvent $event The event
     * @param uim.cake.Core\IContainer $container The container to wrap.
     * @return uim.cake.Core\IContainer|null
     */
    function modifyContainer(IEvent $event, IContainer $container): ?IContainer
    {
        if (empty(this.containerServices)) {
            return null;
        }
        foreach (this.containerServices as $key: $factory) {
            if ($container.has($key)) {
                try {
                    $container.extend($key).setConcrete($factory);
                } catch (NotFoundException $e) {
                    $container.add($key, $factory);
                }
            } else {
                $container.add($key, $factory);
            }
        }

        return $container;
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
        _appArgs = null;
        _appClass = null;
        this.containerServices = [];
    }
}
