


 *


 * @since         3.3.0
  */
module uim.cake.Event;

use ArrayAccess;
use Countable;

/**
 * The Event List
 */
class EventList : ArrayAccess, Countable
{
    /**
     * Events list
     *
     * @var array<uim.cake.events.EventInterface>
     */
    protected $_events = [];

    /**
     * Empties the list of dispatched events.
     */
    void flush(): void
    {
        _events = [];
    }

    /**
     * Adds an event to the list when event listing is enabled.
     *
     * @param uim.cake.events.IEvent $event An event to the list of dispatched events.
     */
    void add(IEvent $event): void
    {
        _events[] = $event;
    }

    /**
     * Whether a offset exists
     *
     * @link https://secure.php.net/manual/en/arrayaccess.offsetexists.php
     * @param mixed $offset An offset to check for.
     * @return bool True on success or false on failure.
     */
    function offsetExists($offset): bool
    {
        return isset(_events[$offset]);
    }

    /**
     * Offset to retrieve
     *
     * @link https://secure.php.net/manual/en/arrayaccess.offsetget.php
     * @param mixed $offset The offset to retrieve.
     * @return mixed Can return all value types.
     */
    #[\ReturnTypeWillChange]
    function offsetGet($offset) {
        if (this.offsetExists($offset)) {
            return _events[$offset];
        }

        return null;
    }

    /**
     * Offset to set
     *
     * @link https://secure.php.net/manual/en/arrayaccess.offsetset.php
     * @param mixed $offset The offset to assign the value to.
     * @param mixed $value The value to set.
     */
    void offsetSet($offset, $value): void
    {
        _events[$offset] = $value;
    }

    /**
     * Offset to unset
     *
     * @link https://secure.php.net/manual/en/arrayaccess.offsetunset.php
     * @param mixed $offset The offset to unset.
     */
    void offsetUnset($offset): void
    {
        unset(_events[$offset]);
    }

    /**
     * Count elements of an object
     *
     * @link https://secure.php.net/manual/en/countable.count.php
     * @return int The custom count as an integer.
     */
    function count(): int
    {
        return count(_events);
    }

    /**
     * Checks if an event is in the list.
     *
     * @param string $name Event name.
     * @return bool
     */
    function hasEvent(string $name): bool
    {
        foreach (_events as $event) {
            if ($event.getName() == $name) {
                return true;
            }
        }

        return false;
    }
}
