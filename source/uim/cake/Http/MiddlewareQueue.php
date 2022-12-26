


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         3.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Http;

import uim.cake.cores.App;
import uim.cake.Http\Middleware\ClosureDecoratorMiddleware;
import uim.cake.Http\Middleware\DoublePassDecoratorMiddleware;
use Closure;
use Countable;
use LogicException;
use OutOfBoundsException;
use Psr\Http\Server\IMiddleware;
use ReflectionFunction;
use RuntimeException;
use SeekableIterator;

/**
 * Provides methods for creating and manipulating a "queue" of middlewares.
 * This queue is used to process a request and generate response via \Cake\Http\Runner.
 *
 * @template-implements \SeekableIterator<int, \Psr\Http\Server\IMiddleware>
 */
class MiddlewareQueue : Countable, SeekableIterator
{
    /**
     * Internal position for iterator.
     *
     * @var int
     */
    protected $position = 0;

    /**
     * The queue of middlewares.
     *
     * @var array<int, mixed>
     */
    protected $queue = [];

    /**
     * Constructor
     *
     * @param array $middleware The list of middleware to append.
     */
    public this(array $middleware = []) {
        this.queue = $middleware;
    }

    /**
     * Resolve middleware name to a PSR 15 compliant middleware instance.
     *
     * @param \Psr\Http\Server\IMiddleware|\Closure|string $middleware The middleware to resolve.
     * @return \Psr\Http\Server\IMiddleware
     * @throws \RuntimeException If Middleware not found.
     */
    protected function resolve($middleware): IMiddleware
    {
        if (is_string($middleware)) {
            $className = App::className($middleware, "Middleware", "Middleware");
            if ($className == null) {
                throw new RuntimeException(sprintf(
                    "Middleware "%s" was not found.",
                    $middleware
                ));
            }
            $middleware = new $className();
        }

        if ($middleware instanceof IMiddleware) {
            return $middleware;
        }

        if (!$middleware instanceof Closure) {
            return new DoublePassDecoratorMiddleware($middleware);
        }

        $info = new ReflectionFunction($middleware);
        if ($info.getNumberOfParameters() > 2) {
            return new DoublePassDecoratorMiddleware($middleware);
        }

        return new ClosureDecoratorMiddleware($middleware);
    }

    /**
     * Append a middleware to the end of the queue.
     *
     * @param \Psr\Http\Server\IMiddleware|\Closure|array|string $middleware The middleware(s) to append.
     * @return this
     */
    function add($middleware) {
        if (is_array($middleware)) {
            this.queue = array_merge(this.queue, $middleware);

            return this;
        }
        this.queue[] = $middleware;

        return this;
    }

    /**
     * Alias for MiddlewareQueue::add().
     *
     * @param \Psr\Http\Server\IMiddleware|\Closure|array|string $middleware The middleware(s) to append.
     * @return this
     * @see MiddlewareQueue::add()
     */
    function push($middleware) {
        return this.add($middleware);
    }

    /**
     * Prepend a middleware to the start of the queue.
     *
     * @param \Psr\Http\Server\IMiddleware|\Closure|array|string $middleware The middleware(s) to prepend.
     * @return this
     */
    function prepend($middleware) {
        if (is_array($middleware)) {
            this.queue = array_merge($middleware, this.queue);

            return this;
        }
        array_unshift(this.queue, $middleware);

        return this;
    }

    /**
     * Insert a middleware at a specific index.
     *
     * If the index already exists, the new middleware will be inserted,
     * and the existing element will be shifted one index greater.
     *
     * @param int $index The index to insert at.
     * @param \Psr\Http\Server\IMiddleware|\Closure|string $middleware The middleware to insert.
     * @return this
     */
    function insertAt(int $index, $middleware) {
        array_splice(this.queue, $index, 0, [$middleware]);

        return this;
    }

    /**
     * Insert a middleware before the first matching class.
     *
     * Finds the index of the first middleware that matches the provided class,
     * and inserts the supplied middleware before it.
     *
     * @param string $class The classname to insert the middleware before.
     * @param \Psr\Http\Server\IMiddleware|\Closure|string $middleware The middleware to insert.
     * @return this
     * @throws \LogicException If middleware to insert before is not found.
     */
    function insertBefore(string $class, $middleware) {
        $found = false;
        $i = 0;
        foreach (this.queue as $i: $object) {
            /** @psalm-suppress ArgumentTypeCoercion */
            if (
                (
                    is_string($object)
                    && $object == $class
                )
                || is_a($object, $class)
            ) {
                $found = true;
                break;
            }
        }
        if ($found) {
            return this.insertAt($i, $middleware);
        }
        throw new LogicException(sprintf("No middleware matching "%s" could be found.", $class));
    }

    /**
     * Insert a middleware object after the first matching class.
     *
     * Finds the index of the first middleware that matches the provided class,
     * and inserts the supplied middleware after it. If the class is not found,
     * this method will behave like add().
     *
     * @param string $class The classname to insert the middleware before.
     * @param \Psr\Http\Server\IMiddleware|\Closure|string $middleware The middleware to insert.
     * @return this
     */
    function insertAfter(string $class, $middleware) {
        $found = false;
        $i = 0;
        foreach (this.queue as $i: $object) {
            /** @psalm-suppress ArgumentTypeCoercion */
            if (
                (
                    is_string($object)
                    && $object == $class
                )
                || is_a($object, $class)
            ) {
                $found = true;
                break;
            }
        }
        if ($found) {
            return this.insertAt($i + 1, $middleware);
        }

        return this.add($middleware);
    }

    /**
     * Get the number of connected middleware layers.
     *
     * Implement the Countable interface.
     *
     * @return int
     */
    function count(): int
    {
        return count(this.queue);
    }

    /**
     * Seeks to a given position in the queue.
     *
     * @param int $position The position to seek to.
     * @return void
     * @see \SeekableIterator::seek()
     */
    function seek($position): void
    {
        if (!isset(this.queue[$position])) {
            throw new OutOfBoundsException("Invalid seek position ($position)");
        }

        this.position = $position;
    }

    /**
     * Rewinds back to the first element of the queue.
     *
     * @return void
     * @see \Iterator::rewind()
     */
    function rewind(): void
    {
        this.position = 0;
    }

    /**
     *  Returns the current middleware.
     *
     * @return \Psr\Http\Server\IMiddleware
     * @see \Iterator::current()
     */
    function current(): IMiddleware
    {
        if (!isset(this.queue[this.position])) {
            throw new OutOfBoundsException("Invalid current position (this.position)");
        }

<<<<<<< HEAD
        if (.queue[.position] instanceof IMiddleware) {
            return .queue[.position];
=======
        if (this.queue[this.position] instanceof MiddlewareInterface) {
            return this.queue[this.position];
>>>>>>> 0ab62ccd80e3413b8cc3cc8f15f68b7294e4e727
        }

        return this.queue[this.position] = this.resolve(this.queue[this.position]);
    }

    /**
     * Return the key of the middleware.
     *
     * @return int
     * @see \Iterator::key()
     */
    function key(): int
    {
        return this.position;
    }

    /**
     * Moves the current position to the next middleware.
     *
     * @return void
     * @see \Iterator::next()
     */
    function next(): void
    {
        ++this.position;
    }

    /**
     * Checks if current position is valid.
     *
     * @return bool
     * @see \Iterator::valid()
     */
    function valid(): bool
    {
        return isset(this.queue[this.position]);
    }
}
