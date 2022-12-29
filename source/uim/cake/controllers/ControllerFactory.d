module uim.cake.controllers;

import uim.cake.controllers\Exception\InvalidParameterException;
import uim.cake.core.App;
import uim.cake.core.IContainer;
import uim.caketps\IControllerFactory;
import uim.caketps\Exception\MissingControllerException;
import uim.caketps\MiddlewareQueue;
import uim.caketps\Runner;
import uim.caketps\ServerRequest;
import uim.cakeilities.Inflector;
use Closure;
use Psr\Http\Message\IResponse;
use Psr\Http\Message\IServerRequest;
use Psr\Http\Server\IRequestHandler;
use ReflectionClass;
use ReflectionFunction;
use ReflectionNamedType;

/**
 * Factory method for building controllers for request.
 *
 * @: uim.cake.Http\IControllerFactory<uim.cake.Controller\Controller>
 */
class ControllerFactory : IControllerFactory, IRequestHandler
{
    /**
     * @var uim.cake.Core\IContainer
     */
    protected myContainer;

    /**
     * @var uim.cake.controllers.Controller
     */
    protected controller;

    /**
     * Constructor
     *
     * @param uim.cake.Core\IContainer myContainer The container to build controllers with.
     */
    this(IContainer myContainer) {
        this.container = myContainer;
    }

    /**
     * Create a controller for a given request.
     *
     * @param \Psr\Http\Message\IServerRequest myRequest The request to build a controller for.
     * @return uim.cake.controllers.Controller
     * @throws uim.cake.http.Exception\MissingControllerException
     */
    Controller create(IServerRequest myRequest) {
        myClassName = this.getControllerClass(myRequest);
        if (myClassName is null) {
            throw this.missingController(myRequest);
        }

        $reflection = new ReflectionClass(myClassName);
        if ($reflection.isAbstract()) {
            throw this.missingController(myRequest);
        }

        // If the controller has a container definition
        // add the request as a service.
        if (this.container.has(myClassName)) {
            this.container.add(ServerRequest::class, myRequest);
            $controller = this.container.get(myClassName);
        } else {
            $controller = $reflection.newInstance(myRequest);
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
    IResponse invoke($controller) {
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
     * @param \Psr\Http\Message\IServerRequest myRequest Request instance.
     * @return \Psr\Http\Message\IResponse
     */
    IResponse handle(IServerRequest myRequest) {
        $controller = this.controller;
        /** @psalm-suppress ArgumentTypeCoercion */
        $controller.setRequest(myRequest);

        myResult = $controller.startupProcess();
        if (myResult instanceof IResponse) {
            return myResult;
        }

        $action = $controller.getAction();
        $args = this.getActionArgs(
            $action,
            array_values((array)$controller.getRequest().getParam("pass"))
        );
        $controller.invokeAction($action, $args);

        myResult = $controller.shutdownProcess();
        if (myResult instanceof IResponse) {
            return myResult;
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
    protected array getActionArgs(Closure $action, array $passedParams) {
        $resolved = [];
        $function = new ReflectionFunction($action);
        foreach ($function.getParameters() as $parameter) {
            myType = $parameter.getType();
            if (myType && !myType instanceof ReflectionNamedType) {
                // Only single types are supported
                throw new InvalidParameterException([
                    "template":"unsupported_type",
                    "parameter":$parameter.getName(),
                    "controller":this.controller.getName(),
                    "action":this.controller.getRequest().getParam("action"),
                    "prefix":this.controller.getRequest().getParam("prefix"),
                    "plugin":this.controller.getRequest().getParam("plugin"),
                ]);
            }

            // Check for dependency injection for classes
            if (myType instanceof ReflectionNamedType && !myType.isBuiltin()) {
                if (this.container.has(myType.getName())) {
                    $resolved[] = this.container.get(myType.getName());
                    continue;
                }

                // Add default value if provided
                // Do not allow positional arguments for classes
                if ($parameter.isDefaultValueAvailable()) {
                    $resolved[] = $parameter.getDefaultValue();
                    continue;
                }

                throw new InvalidParameterException([
                    "template":"missing_dependency",
                    "parameter":$parameter.getName(),
                    "controller":this.controller.getName(),
                    "action":this.controller.getRequest().getParam("action"),
                    "prefix":this.controller.getRequest().getParam("prefix"),
                    "plugin":this.controller.getRequest().getParam("plugin"),
                ]);
            }

            // Use any passed params as positional arguments
            if ($passedParams) {
                $argument = array_shift($passedParams);
                if (myType instanceof ReflectionNamedType) {
                    myTypedArgument = this.coerceStringToType($argument, myType);

                    if (myTypedArgument is null) {
                        throw new InvalidParameterException([
                            "template":"failed_coercion",
                            "passed":$argument,
                            "type":myType.getName(),
                            "parameter":$parameter.getName(),
                            "controller":this.controller.getName(),
                            "action":this.controller.getRequest().getParam("action"),
                            "prefix":this.controller.getRequest().getParam("prefix"),
                            "plugin":this.controller.getRequest().getParam("plugin"),
                        ]);
                    }
                    $argument = myTypedArgument;
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
                "template":"missing_parameter",
                "parameter":$parameter.getName(),
                "controller":this.controller.getName(),
                "action":this.controller.getRequest().getParam("action"),
                "prefix":this.controller.getRequest().getParam("prefix"),
                "plugin":this.controller.getRequest().getParam("plugin"),
            ]);
        }

        return array_merge($resolved, $passedParams);
    }

    /**
     * Coerces string argument to primitive type.
     *
     * @param string argument Argument to coerce
     * @param \ReflectionNamedType myType Parameter type
     * @return array|string|float|int|bool|null
     */
    protected auto coerceStringToType(string argument, ReflectionNamedType myType) {
        switch (myType.getName()) {
            case "string":
                return $argument;
            case "float":
                return is_numeric($argument) ? (float)$argument : null;
            case "int":
                return ctype_digit($argument) ? (int)$argument : null;
            case "bool":
                return $argument == "0" ? false : ($argument == "1" ? true : null);
            case "array":
                return explode(",", $argument);
        }

        return null;
    }

    /**
     * Determine the controller class name based on current request and controller param
     *
     * @param uim.cake.http.ServerRequest myRequest The request to build a controller for.
     * @return string|null
     * @psalm-return class-string<uim.cake.Controller\Controller>|null
     */
    Nullable!string getControllerClass(ServerRequest myRequest) {
        myPluginPath = "";
        $module = "Controller";
        $controller = myRequest.getParam("controller", "");
        if (myRequest.getParam("plugin")) {
            myPluginPath = myRequest.getParam("plugin") . ".";
        }
        if (myRequest.getParam("prefix")) {
            $prefix = myRequest.getParam("prefix");

            $firstChar = substr($prefix, 0, 1);
            if ($firstChar != strtoupper($firstChar)) {
                deprecationWarning(
                    "The `{$prefix}` prefix did not start with an upper case character. " .
                    "Routing prefixes should be defined as CamelCase values. " .
                    "Prefix inflection will be removed in 5.0"
                );

                if (indexOf($prefix, "/") == false) {
                    $module .= "/" . Inflector::camelize($prefix);
                } else {
                    $prefixes = array_map(
                        function ($val) {
                            return Inflector::camelize($val);
                        },
                        explode("/", $prefix)
                    );
                    $module .= "/" . implode("/", $prefixes);
                }
            } else {
                $module .= "/" . $prefix;
            }
        }
        $firstChar = substr($controller, 0, 1);

        // Disallow plugin short forms, / and \\ from
        // controller names as they allow direct references to
        // be created.
        if (
            indexOf($controller, "\\") != false ||
            indexOf($controller, "/") != false ||
            indexOf($controller, ".") != false ||
            $firstChar == strtolower($firstChar)
        ) {
            throw this.missingController(myRequest);
        }

        /** @var class-string<uim.cake.Controller\Controller>|null */
        return App::className(myPluginPath . $controller, $module, "Controller");
    }

    /**
     * Throws an exception when a controller is missing.
     *
     * @param uim.cake.http.ServerRequest myRequest The request.
     * @return uim.cake.http.Exception\MissingControllerException
     */
    protected auto missingController(ServerRequest myRequest) {
        return new MissingControllerException([
            "class":myRequest.getParam("controller"),
            "plugin":myRequest.getParam("plugin"),
            "prefix":myRequest.getParam("prefix"),
            "_ext":myRequest.getParam("_ext"),
        ]);
    }
}
