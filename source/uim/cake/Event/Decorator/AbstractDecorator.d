module uim.cake.Event\Decorator;

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
    protected $_callable;

    /**
     * Decorator options
     *
     * @var array
     */
    protected $_options = [];

    /**
     * Constructor.
     *
     * @param callable $callable Callable.
     * @param array<string, mixed> myOptions Decorator options.
     */
    this(callable $callable, array myOptions = []) {
        this._callable = $callable;
        this._options = myOptions;
    }

    /**
     * Invoke
     *
     * @link https://secure.php.net/manual/en/language.oop5.magic.php#object.invoke
     * @return mixed
     */
    auto __invoke() {
        return this._call(func_get_args());
    }

    /**
     * Calls the decorated callable with the passed arguments.
     *
     * @param array $args Arguments for the callable.
     * @return mixed
     */
    protected auto _call(array $args) {
        $callable = this._callable;

        return $callable(...$args);
    }
}
