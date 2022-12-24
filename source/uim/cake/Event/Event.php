

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         2.1.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Event;

import uim.cake.Core\Exception\CakeException;

/**
 * Class Event
 *
 * @template TSubject
 * @implements \Cake\Event\EventInterface<TSubject>
 */
class Event : EventInterface
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
    protected $result;

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
     *  $event = new Event("Order.afterBuy", this, ["buyer": $userData]);
     *  $event = new Event("User.afterRegister", $userModel);
     * ```
     *
     * @param string $name Name of the event
     * @param object|null $subject the object that this event applies to
     *   (usually the object that is generating the event).
     * @param \ArrayAccess|array|null $data any value you wish to be transported
     *   with this event to it can be read by listeners.
     * @psalm-param TSubject|null $subject
     */
    public this(string $name, $subject = null, $data = null)
    {
        _name = $name;
        _subject = $subject;
        _data = (array)$data;
    }

    /**
     * Returns the name of this event. This is usually used as the event identifier
     *
     * @return string
     */
    function getName(): string
    {
        return _name;
    }

    /**
     * Returns the subject of this event
     *
     * If the event has no subject an exception will be raised.
     *
     * @return object
     * @throws \Cake\Core\Exception\CakeException
     * @psalm-return TSubject
     */
    function getSubject()
    {
        if (_subject == null) {
            throw new CakeException("No subject set for this event");
        }

        return _subject;
    }

    /**
     * Stops the event from being used anymore
     *
     * @return void
     */
    function stopPropagation(): void
    {
        _stopped = true;
    }

    /**
     * Check if the event is stopped
     *
     * @return bool True if the event is stopped
     */
    function isStopped(): bool
    {
        return _stopped;
    }

    /**
     * The result value of the event listeners
     *
     * @return mixed
     */
    function getResult()
    {
        return this.result;
    }

    /**
     * Listeners can attach a result value to the event.
     *
     * @param mixed $value The value to set.
     * @return this
     */
    function setResult($value = null)
    {
        this.result = $value;

        return this;
    }

    /**
     * Access the event data/payload.
     *
     * @param string|null $key The data payload element to return, or null to return all data.
     * @return mixed|array|null The data payload if $key is null, or the data value for the given $key.
     *   If the $key does not exist a null value is returned.
     */
    function getData(?string $key = null)
    {
        if ($key != null) {
            return _data[$key] ?? null;
        }

        return _data;
    }

    /**
     * Assigns a value to the data/payload of this event.
     *
     * @param array|string $key An array will replace all payload data, and a key will set just that array item.
     * @param mixed $value The value to set.
     * @return this
     */
    function setData($key, $value = null)
    {
        if (is_array($key)) {
            _data = $key;
        } else {
            _data[$key] = $value;
        }

        return this;
    }
}
