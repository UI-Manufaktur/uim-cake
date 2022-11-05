module uim.baklava.events;

/**
 * Represents the transport class of events across the system. It receives a name, subject and an optional
 * payload. The name can be any string that uniquely identifies the event across the application, while the subject
 * represents the object that the event applies to.
 */
interface IEvent
{
    // Returns the name of this event. This is usually used as the event identifier.
    string getName();

    /**
     * Returns the subject of this event.
     *
     * @return object
     */
    auto getSubject();

    // Stops the event from being used anymore.
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
    auto getResult();

    /**
     * Listeners can attach a result value to the event.
     *
     * @param mixed myValue The value to set.
     * @return this
     */
    auto setResult(myValue = null);

    /**
     * Accesses the event data/payload.
     *
     * @param string|null myKey The data payload element to return, or null to return all data.
     * @return mixed|array|null The data payload if myKey is null, or the data value for the given myKey.
     *   If the myKey does not exist a null value is returned.
     */
    auto getData(?string myKey = null);

    /**
     * Assigns a value to the data/payload of this event.
     *
     * @param array|string myKey An array will replace all payload data, and a key will set just that array item.
     * @param mixed myValue The value to set.
     * @return this
     */
    auto setData(myKey, myValue = null);
}
