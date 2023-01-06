/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.Event;

@safe:
import uim.cake;

/**
 * Objects implementing this interface should declare the `implementedEvents()` method
 * to notify the event manager what methods should be called when an event is triggered.
 */
interface IEventListener
{
    /**
     * Returns a list of events this object is implementing. When the class is registered
     * in an event manager, each individual method will be associated with the respective event.
     *
     * ### Example:
     *
     * ```
     *  function implementedEvents()
     *  {
     *      return [
     *          "Order.complete":"sendEmail",
     *          "Article.afterBuy":"decrementInventory",
     *          "User.onRegister":["callable":"logRegistration", "priority":20, "passParams":true]
     *      ];
     *  }
     * ```
     *
     * @return array<string, mixed> Associative array or event key names pointing to the function
     * that should be called in the object when the respective event is fired
     */
    array implementedEvents();
}
