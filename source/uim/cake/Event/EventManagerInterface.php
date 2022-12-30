

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *


 * @since         3.6.0

 */module uim.cake.Event;

/**
 * Interface IEventManager
 */
interface IEventManager
{
    /**
     * Adds a new listener to an event.
     *
     * A variadic interface to add listeners that emulates jQuery.on().
     *
     * Binding an IEventListener:
     *
     * ```
     * $eventManager.on($listener);
     * ```
     *
     * Binding with no options:
     *
     * ```
     * $eventManager.on("Model.beforeSave", $callable);
     * ```
     *
     * Binding with options:
     *
     * ```
     * $eventManager.on("Model.beforeSave", ["priority": 90], $callable);
     * ```
     *
     * @param uim.cake.events.IEventListener|string $eventKey The event unique identifier name
     * with which the callback will be associated. If $eventKey is an instance of
     * Cake\events.IEventListener its events will be bound using the `implementedEvents()` methods.
     *
     * @param callable|array $options Either an array of options or the callable you wish to
     * bind to $eventKey. If an array of options, the `priority` key can be used to define the order.
     * Priorities are treated as queues. Lower values are called before higher ones, and multiple attachments
     * added to the same priority queue will be treated in the order of insertion.
     *
     * @param callable|null $callable The callable function you want invoked.
     * @return this
     * @throws \InvalidArgumentException When event key is missing or callable is not an
     *   instance of Cake\events.IEventListener.
     */
    function on($eventKey, $options = [], ?callable $callable = null);

    /**
     * Remove a listener from the active listeners.
     *
     * Remove a IEventListener entirely:
     *
     * ```
     * $manager.off($listener);
     * ```
     *
     * Remove all listeners for a given event:
     *
     * ```
     * $manager.off("My.event");
     * ```
     *
     * Remove a specific listener:
     *
     * ```
     * $manager.off("My.event", $callback);
     * ```
     *
     * Remove a callback from all events:
     *
     * ```
     * $manager.off($callback);
     * ```
     *
     * @param uim.cake.events.IEventListener|callable|string $eventKey The event unique identifier name
     *   with which the callback has been associated, or the $listener you want to remove.
     * @param uim.cake.events.IEventListener|callable|null $callable The callback you want to detach.
     * @return this
     */
    function off($eventKey, $callable = null);

    /**
     * Dispatches a new event to all configured listeners
     *
     * @param uim.cake.events.EventInterface|string $event The event key name or instance of EventInterface.
     * @return uim.cake.events.EventInterface
     * @triggers $event
     */
    function dispatch($event): EventInterface;

    /**
     * Returns a list of all listeners for an eventKey in the order they should be called
     *
     * @param string $eventKey Event key.
     */
    array listeners(string $eventKey): array;
}
