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
    protected _options = [];

    /**
     * Constructor.
     *
     * @param callable $callable Callable.
     * @param array<string, mixed> $options Decorator options.
     */
    this(callable $callable, STRINGAA someOptions = []) {
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
