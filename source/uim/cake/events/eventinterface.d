/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.Event;

@safe:
import uim.cake;

/**
 * Represents the transport class of events across the system. It receives a name, subject and an optional
 * payload. The name can be any string that uniquely identifies the event across the application, while the subject
 * represents the object that the event applies to.
 *
 * @template TSubject
 */
interface IEvent
{
    /**
     * Returns the name of this event. This is usually used as the event identifier.
     */
    string getName();

    /**
     * Returns the subject of this event.
     *
     * @return object
     * @psalm-return TSubject
     */
    function getSubject();

    /**
     * Stops the event from being used anymore.
     */
    void stopPropagation();

    /**
     * Checks if the event is stopped.
     *
     * @return bool True if the event is stopped
     */
    bool isStopped();

    /**
     * The result value of the event listeners.
     *
     * @return mixed
     */
    function getResult();

    /**
     * Listeners can attach a result value to the event.
     *
     * @param mixed $value The value to set.
     * @return this
     */
    function setResult($value = null);

    /**
     * Accesses the event data/payload.
     *
     * @param string|null $key The data payload element to return, or null to return all data.
     * @return mixed|array|null The data payload if $key is null, or the data value for the given $key.
     *   If the $key does not exist a null value is returned.
     */
    function getData(Nullable!string aKey = null);

    /**
     * Assigns a value to the data/payload of this event.
     *
     * @param array|string aKey An array will replace all payload data, and a key will set just that array item.
     * @param mixed $value The value to set.
     * @return this
     */
    function setData($key, $value = null);
}
