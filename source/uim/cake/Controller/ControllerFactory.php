


 *


 * @since         3.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Controller;

import uim.cake.controllers.exceptions.InvalidParameterException;
import uim.cake.cores.App;
import uim.cake.cores.IContainer;
import uim.cake.http.ControllerFactoryInterface;
import uim.cake.http.Exception\MissingControllerException;
import uim.cake.http.MiddlewareQueue;
import uim.cake.http.Runner;
import uim.cake.http.ServerRequest;
import uim.cake.utilities.Inflector;
use Closure;
use Psr\Http\Message\IResponse;
use Psr\Http\Message\IServerRequest;
use Psr\Http\Server\RequestHandlerInterface;
use ReflectionClass;
use ReflectionFunction;
use ReflectionNamedType;

/**
 * Factory method for building controllers for request.
 *
 * @implements \Cake\Http\ControllerFactoryInterface<\Cake\Controller\Controller>
 */
class ControllerFactory : ControllerFactoryInterface, RequestHandlerInterface
{
    /**
     * @var uim.cake.Core\IContainer
     */
    protected $container;

    /**
     * @var uim.cake.controllers.Controller
     */
    protected $controller;

    /**
     * Constructor
     *
     * @param uim.cake.Core\IContainer $container The container to build controllers with.
     */
    public this(IContainer $container) {
        this.container = $container;
    }

    /**
     * Create a controller for a given request.
     *
     * @param \Psr\Http\Message\IServerRequest $request The request to build a controller for.
     * @return uim.cake.controllers.Controller
     * @throws uim.cake.http.Exception\MissingControllerException
     */
    function create(IServerRequest $request): Controller
    {
        $className = this.getControllerClass($request);
        if ($className == null) {
            throw this.missingController($request);
        }

        $reflection = new ReflectionClass($className);
        if ($reflection.isAbstract()) {
            throw this.missingController($request);
        }

        // Get the controller from the container if defined.
        // The request is in the container by default.
        if (this.container.has($className)) {
            $controller = this.container.get($className);
        } else {
            $controller = $reflection.newInstance($request);
        }

        return $controller;
    }

    /**
     * Invoke a controller"s action and wrapping methods.
     *
     * @param uim.cake.controllers.Controller $controller The controller to invoke.
     * @return \Psr\Http\Message\IResponse The response
     * @throws uim.cake.controllers.Exception\MissingActionException If controller action is not found.
     * @throws \UnexpectedValueException If return value of action method is not null or IResponse instance.
     */
    function invoke($controller): IResponse
    {
        this.controller = $controller;

        $middlewares = $controller.getMiddleware();

        if ($middlewares) {
            $middlewareQueue = new MiddlewareQueue($middlewares);
            $runner = new Runner();

            return $runner.run($middlewareQueue, $controller.getRequest(), this);
        }

        return this.handle($controller.getRequest());
    }

    /**
     * Invoke the action.
     *
     * @param \Psr\Http\Message\IServerRequest $request Request instance.
     * @return \Psr\Http\Message\IResponse
     */
    function handle(IServerRequest $request): IResponse
    {
        $controller = this.controller;
        /** @psalm-suppress ArgumentTypeCoercion */
        $controller.setRequest($request);

        $result = $controller.startupProcess();
        if ($result instanceof IResponse) {
            return $result;
        }

        $action = $controller.getAction();
        $args = this.getActionArgs(
            $action,
            array_values((array)$controller.getRequest().getParam("pass"))
        );
        $controller.invokeAction($action, $args);

        $result = $controller.shutdownProcess();
        if ($result instanceof IResponse) {
            return $result;
        }

        return $controller.getResponse();
    }

    /**
     * Get the arguments for the controller action invocation.
     *
     * @param \Closure $action Controller action.
     * @param array $passedParams Params passed by the router.
     * @return array
     */
    protected function getActionArgs(Closure $action, array $passedParams): array
    {
        $resolved = [];
        $function = new ReflectionFunction($action);
        foreach ($function.getParameters() as $parameter) {
            $type = $parameter.getType();
            if ($type && !$type instanceof ReflectionNamedType) {
                // Only single types are supported
                throw new InvalidParameterException([
                    "template": "unsupported_type",
                    "parameter": $parameter.getName(),
                    "controller": this.controller.getName(),
                    "action": this.controller.getRequest().getParam("action"),
                    "prefix": this.controller.getRequest().getParam("prefix"),
                    "plugin": this.controller.getRequest().getParam("plugin"),
                ]);
            }

            // Check for dependency injection for classes
            if ($type instanceof ReflectionNamedType && !$type.isBuiltin()) {
                $typeName = $type.getName();
                if (this.container.has($typeName)) {
                    $resolved[] = this.container.get($typeName);
                    continue;
                }

                // Use passedParams as a source of typed dependencies.
                // The accepted types for passedParams was never defined and userland code relies on that.
                if ($passedParams && is_object($passedParams[0]) && $passedParams[0] instanceof $typeName) {
                    $resolved[] = array_shift($passedParams);
                    continue;
                }

                // Add default value if provided
                // Do not allow positional arguments for classes
                if ($parameter.isDefaultValueAvailable()) {
                    $resolved[] = $parameter.getDefaultValue();
                    continue;
                }

                throw new InvalidParameterException([
                    "template": "missing_dependency",
                    "parameter": $parameter.getName(),
                    "type": $typeName,
                    "controller": this.controller.getName(),
                    "action": this.controller.getRequest().getParam("action"),
                    "prefix": this.controller.getRequest().getParam("prefix"),
                    "plugin": this.controller.getRequest().getParam("plugin"),
                ]);
            }

            // Use any passed params as positional arguments
            if ($passedParams) {
                $argument = array_shift($passedParams);
                if (is_string($argument) && $type instanceof ReflectionNamedType) {
                    $typedArgument = this.coerceStringToType($argument, $type);

                    if ($typedArgument == null) {
                        throw new InvalidParameterException([
                            "template": "failed_coercion",
                            "passed": $argument,
                            "type": $type.getName(),
                            "parameter": $parameter.getName(),
                            "controller": this.controller.getName(),
                            "action": this.controller.getRequest().getParam("action"),
                            "prefix": this.controller.getRequest().getParam("prefix"),
                            "plugin": this.controller.getRequest().getParam("plugin"),
                        ]);
                    }
                    $argument = $typedArgument;
                }

                $resolved[] = $argument;
                continue;
            }

            // Add default value if provided
            if ($parameter.isDefaultValueAvailable()) {
                $resolved[] = $parameter.getDefaultValue();
                continue;
            }

            // Variadic parameter can have 0 arguments
            if ($parameter.isVariadic()) {
                continue;
            }

            throw new InvalidParameterException([
                "template": "missing_parameter",
                "parameter": $parameter.getName(),
                "controller": this.controller.getName(),
                "action": this.controller.getRequest().getParam("action"),
                "prefix": this.controller.getRequest().getParam("prefix"),
                "plugin": this.controller.getRequest().getParam("plugin"),
            ]);
        }

        return array_merge($resolved, $passedParams);
    }

    /**
     * Coerces string argument to primitive type.
     *
     * @param string $argument Argument to coerce
     * @param \ReflectionNamedType $type Parameter type
     * @return array|string|float|int|bool|null
     */
    protected function coerceStringToType(string $argument, ReflectionNamedType $type) {
        switch ($type.getName()) {
            case "string":
                return $argument;
            case "float":
                return is_numeric($argument) ? (float)$argument : null;
            case "int":
                return filter_var($argument, FILTER_VALIDATE_INT, FILTER_NULL_ON_FAILURE);
            case "bool":
                return $argument == "0" ? false : ($argument == "1" ? true : null);
            case "array":
                return $argument == "" ? [] : explode(",", $argument);
        }

        return null;
    }

    /**
     * Determine the controller class name based on current request and controller param
     *
     * @param uim.cake.http.ServerRequest $request The request to build a controller for.
     * @return string|null
     * @psalm-return class-string<\Cake\Controller\Controller>|null
     */
    function getControllerClass(ServerRequest $request): ?string
    {
        $pluginPath = "";
        $namespace = "Controller";
        $controller = $request.getParam("controller", "");
        if ($request.getParam("plugin")) {
            $pluginPath = $request.getParam("plugin") . ".";
        }
        if ($request.getParam("prefix")) {
            $prefix = $request.getParam("prefix");

            $firstChar = substr($prefix, 0, 1);
            if ($firstChar != strtoupper($firstChar)) {
                deprecationWarning(
                    "The `{$prefix}` prefix did not start with an upper case character. " .
                    "Routing prefixes should be defined as CamelCase values. " .
                    "Prefix inflection will be removed in 5.0"
                );

                if (strpos($prefix, "/") == false) {
                    $namespace .= "/" . Inflector::camelize($prefix);
                } else {
                    $prefixes = array_map(
                        function ($val) {
                            return Inflector::camelize($val);
                        },
                        explode("/", $prefix)
                    );
                    $namespace .= "/" . implode("/", $prefixes);
                }
            } else {
                $namespace .= "/" . $prefix;
            }
        }
        $firstChar = substr($controller, 0, 1);

        // Disallow plugin short forms, / and \\ from
        // controller names as they allow direct references to
        // be created.
        if (
            strpos($controller, "\\") != false ||
            strpos($controller, "/") != false ||
            strpos($controller, ".") != false ||
            $firstChar == strtolower($firstChar)
        ) {
            throw this.missingController($request);
        }

        /** @var class-string<\Cake\Controller\Controller>|null */
        return App::className($pluginPath . $controller, $namespace, "Controller");
    }

    /**
     * Throws an exception when a controller is missing.
     *
     * @param uim.cake.http.ServerRequest $request The request.
     * @return uim.cake.http.Exception\MissingControllerException
     */
    protected function missingController(ServerRequest $request) {
        return new MissingControllerException([
            "class": $request.getParam("controller"),
            "plugin": $request.getParam("plugin"),
            "prefix": $request.getParam("prefix"),
            "_ext": $request.getParam("_ext"),
        ]);
    }
}
