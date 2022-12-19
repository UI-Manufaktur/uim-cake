module uim.cake.events;

@safe:
import uim.cake;

// The Event List
 */
class EventList : ArrayAccess, Countable
{
    // Events list
    protected IEvent[] _events;

    /**
     * Empties the list of dispatched events.
     */
    void flush() {
        _events = [];
    }

    /**
     * Adds an event to the list when event listing is enabled.
     *
     * @param \Cake\Event\IEvent myEvent An event to the list of dispatched events.
     * @return void
     */
    void add(IEvent myEvent) {
        _events[] = myEvent;
    }

    /**
     * Whether a offset exists
     *
     * @link https://secure.php.net/manual/en/arrayaccess.offsetexists.php
     * @param mixed $offset An offset to check for.
     * @return bool True on success or false on failure.
     */
    bool offsetExists($offset) {
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
     * @param mixed myValue The value to set.
     * @return void
     */
    void offsetSet($offset, myValue) {
        _events[$offset] = myValue;
    }

    /**
     * Offset to unset
     *
     * @link https://secure.php.net/manual/en/arrayaccess.offsetunset.php
     * @param mixed $offset The offset to unset.
     * @return void
     */
    void offsetUnset($offset) {
        unset(_events[$offset]);
    }

    /**
     * Count elements of an object
     *
     * @link https://secure.php.net/manual/en/countable.count.php
     * @return int The custom count as an integer.
     */
    int count() {
        return count(_events);
    }

    /**
     * Checks if an event is in the list.
     *
     * @param string myName Event name.
     */
    bool hasEvent(string myName) {
        foreach (_events as myEvent) {
            if (myEvent.getName() == myName) {
                return true;
            }
        }

        return false;
    }
}
