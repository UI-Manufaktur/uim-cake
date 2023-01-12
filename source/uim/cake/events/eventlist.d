/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.Event;

@safe:
import uim.cake;

use ArrayAccess;
use Countable;

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
        _events = null;
    }

    /**
     * Adds an event to the list when event listing is enabled.
     *
     * @param uim.cake.events.IEvent myEvent An event to the list of dispatched events.
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
     */
    void offsetSet($offset, myValue) {
        _events[$offset] = myValue;
    }

    /**
     * Offset to unset
     *
     * @link https://secure.php.net/manual/en/arrayaccess.offsetunset.php
     * @param mixed $offset The offset to unset.
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
    size_t count() {
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
