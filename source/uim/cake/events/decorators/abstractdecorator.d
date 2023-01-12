/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.events.Decorator;

/**
 * Common base class for event decorator subclasses.
 */
abstract class AbstractDecorator
{
    /**
     * Callable
     *
     * @var callable
     */
    protected _callable;

    /**
     * Decorator options
     *
     * @var array
     */
    protected _options = null;

    /**
     * Constructor.
     *
     * @param callable $callable Callable.
     * @param array<string, mixed> $options Decorator options.
     */
    this(callable $callable, STRINGAA someOptions = null) {
        _callable = $callable;
        _options = $options;
    }

    /**
     * Invoke
     *
     * @link https://secure.php.net/manual/en/language.oop5.magic.php#object.invoke
     * @return mixed
     */
    function __invoke() {
        return _call(func_get_args());
    }

    /**
     * Calls the decorated callable with the passed arguments.
     *
     * @param array $args Arguments for the callable.
     * @return mixed
     */
    protected function _call(array $args) {
        $callable = _callable;

        return $callable(...$args);
    }
}
