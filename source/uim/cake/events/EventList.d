module uim.cake.events;

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
     * @var array<\Cake\Event\IEvent>
     */
    protected $_events = [];

    /**
     * Empties the list of dispatched events.
     */
    void flush() {
        this._events = [];
    }

    /**
     * Adds an event to the list when event listing is enabled.
     *
     * @param \Cake\Event\IEvent myEvent An event to the list of dispatched events.
     */
    void add(IEvent myEvent) {
        this._events[] = myEvent;
    }

    /**
     * Whether a offset exists
     *
     * @link https://secure.php.net/manual/en/arrayaccess.offsetexists.php
     * @param mixed $offset An offset to check for.
     * @return bool True on success or false on failure.
     */
    bool offsetExists($offset) {
        return isset(this._events[$offset]);
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
            return this._events[$offset];
        }

        return null;
    }

    /**
     * Offset to set
     *
     * @link https://secure.php.net/manual/en/arrayaccess.offsetset.php
     * @param mixed $offset The offset to assign the value to.
     * @param mixed myValue The value to set.
     */
    void offsetSet($offset, myValue) {
        this._events[$offset] = myValue;
    }

    /**
     * Offset to unset
     *
     * @link https://secure.php.net/manual/en/arrayaccess.offsetunset.php
     * @param mixed $offset The offset to unset.
     */
    void offsetUnset($offset) {
        unset(this._events[$offset]);
    }

    /**
     * Count elements of an object
     *
     * @link https://secure.php.net/manual/en/countable.count.php
     * @return int The custom count as an integer.
     */
    int count() {
        return count(this._events);
    }

    /**
     * Checks if an event is in the list.
     *
     * @param string myName Event name.
     */
    bool hasEvent(string myName) {
        foreach (this._events as myEvent) {
            if (myEvent.getName() === myName) {
                return true;
            }
        }

        return false;
    }
}
