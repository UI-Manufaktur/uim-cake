module uim.cake.events;

import uim.cake.core.Exception\CakeException;

/**
 * Class Event
 *
 * @template TSubject
 */
class Event : IEvent
{
    /**
     * Name of the event
     *
     * @var string
     */
    protected $_name;

    /**
     * The object this event applies to (usually the same object that generates the event)
     *
     * @var object|null
     * @psalm-var TSubject|null
     */
    protected $_subject;

    /**
     * Custom data for the method that receives the event
     *
     * @var array
     */
    protected $_data;

    /**
     * Property used to retain the result value of the event listeners
     *
     * Use setResult() and getResult() to set and get the result.
     *
     * @var mixed
     */
    protected myResult;

    /**
     * Flags an event as stopped or not, default is false
     *
     * @var bool
     */
    protected $_stopped = false;

    /**
     * Constructor
     *
     * ### Examples of usage:
     *
     * ```
     *  myEvent = new Event('Order.afterBuy', this, ['buyer' => myUserData]);
     *  myEvent = new Event('User.afterRegister', myUserModel);
     * ```
     *
     * @param string myName Name of the event
     * @param object|null $subject the object that this event applies to
     *   (usually the object that is generating the event).
     * @param \ArrayAccess|array|null myData any value you wish to be transported
     *   with this event to it can be read by listeners.
     * @psalm-param TSubject|null $subject
     */
    this(string myName, $subject = null, myData = null) {
        this._name = myName;
        this._subject = $subject;
        this._data = (array)myData;
    }

    /**
     * Returns the name of this event. This is usually used as the event identifier
     *
     * @return string
     */
    auto getName(): string
    {
        return this._name;
    }

    /**
     * Returns the subject of this event
     *
     * If the event has no subject an exception will be raised.
     *
     * @return object
     * @throws \Cake\Core\Exception\CakeException
     * @psalm-return TSubject
     * @psalm-suppress LessSpecificImplementedReturnType
     */
    auto getSubject() {
        if (this._subject === null) {
            throw new CakeException('No subject set for this event');
        }

        return this._subject;
    }

    /**
     * Stops the event from being used anymore
     *
     * @return void
     */
    function stopPropagation(): void
    {
        this._stopped = true;
    }

    /**
     * Check if the event is stopped
     *
     * @return bool True if the event is stopped
     */
    bool isStopped() {
        return this._stopped;
    }

    /**
     * The result value of the event listeners
     *
     * @return mixed
     */
    auto getResult() {
        return this.result;
    }

    /**
     * Listeners can attach a result value to the event.
     *
     * @param mixed myValue The value to set.
     * @return this
     */
    auto setResult(myValue = null) {
        this.result = myValue;

        return this;
    }

    /**
     * Access the event data/payload.
     *
     * @param string|null myKey The data payload element to return, or null to return all data.
     * @return mixed|array|null The data payload if myKey is null, or the data value for the given myKey.
     *   If the myKey does not exist a null value is returned.
     */
    auto getData(?string myKey = null) {
        if (myKey !== null) {
            return this._data[myKey] ?? null;
        }

        /** @psalm-suppress RedundantCastGivenDocblockType */
        return (array)this._data;
    }

    /**
     * Assigns a value to the data/payload of this event.
     *
     * @param array|string myKey An array will replace all payload data, and a key will set just that array item.
     * @param mixed myValue The value to set.
     * @return this
     */
    auto setData(myKey, myValue = null) {
        if (is_array(myKey)) {
            this._data = myKey;
        } else {
            this._data[myKey] = myValue;
        }

        return this;
    }
}
