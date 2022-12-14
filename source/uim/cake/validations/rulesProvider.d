/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.validations;

use ReflectionClass;

/**
 * A Proxy class used to remove any extra arguments when the user intended to call
 * a method in another class that is not aware of validation providers signature
 *
 * @method bool extension(mixed $check, array $extensions, array $context = [])
 */
class RulesProvider
{
    /**
     * The class/object to proxy.
     *
     * @var object|string
     */
    protected $_class;

    /**
     * The proxied class" reflection
     *
     * @var \ReflectionClass
     */
    protected $_reflection;

    /**
     * Constructor, sets the default class to use for calling methods
     *
     * @param object|string myClass the default class to proxy
     * @throws \ReflectionException
     * @psalm-param object|class-string myClass
     */
    this(myClass = Validation::class) {
        this._class = myClass;
        this._reflection = new ReflectionClass(myClass);
    }

    /**
     * Proxies validation method calls to the Validation class.
     *
     * The last argument (context) will be sliced off, if the validation
     * method"s last parameter is not named "context". This lets
     * the various wrapped validation methods to not receive the validation
     * context unless they need it.
     *
     * @param string $method the validation method to call
     * @param array $arguments the list of arguments to pass to the method
     * @return bool Whether the validation rule passed
     */
    auto __call(string $method, array $arguments) {
        $method = this._reflection.getMethod($method);
        $argumentList = $method.getParameters();
        if (array_pop($argumentList).getName() !== "context") {
            $arguments = array_slice($arguments, 0, -1);
        }
        $object = is_string(this._class) ? null : this._class;

        return $method.invokeArgs($object, $arguments);
    }
}
