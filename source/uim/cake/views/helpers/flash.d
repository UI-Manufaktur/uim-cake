/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.viewss.helpers;

import uim.cake.viewss.helpers;

/**
 * FlashHelper class to render flash messages.
 *
 * After setting messages in your controllers with FlashComponent, you can use
 * this class to output your flash messages in your views.
 */
class FlashHelper : Helper
{
    /**
     * Used to render the message set in FlashComponent::set()
     *
     * In your template file: this.Flash.render("somekey");
     * Will default to flash if no param is passed
     *
     * You can pass additional information into the flash message generation. This allows you
     * to consolidate all the parameters for a given type of flash message into the view.
     *
     * ```
     * echo this.Flash.render("flash", ["params": ["name": myUser["User"]["name"]]]);
     * ```
     *
     * This would pass the current user"s name into the flash message, so you could create personalized
     * messages without the controller needing access to that data.
     *
     * Lastly you can choose the element that is used for rendering the flash message. Using
     * custom elements allows you to fully customize how flash messages are generated.
     *
     * ```
     * echo this.Flash.render("flash", ["element": "my_custom_element"]);
     * ```
     *
     * If you want to use an element from a plugin for rendering your flash message
     * you can use the dot notation for the plugin"s element name:
     *
     * ```
     * echo this.Flash.render("flash", [
     *   "element": "MyPlugin.my_custom_element",
     * ]);
     * ```
     *
     * If you have several messages stored in the Session, each message will be rendered in its own
     * element.
     *
     * @param string myKey The [Flash.]key you are rendering in the view.
     * @param array<string, mixed> myOptions Additional options to use for the creation of this flash message.
     *    Supports the "params", and "element" keys that are used in the helper.
     * @return string|null Rendered flash message or null if flash key does not exist
     *   in session.
     */
    Nullable!string render(string myKey = "flash", array myOptions = null) {
        myMessages = _View.getRequest().getFlash().consume(myKey);
        if (myMessages is null) {
            return null;
        }

        $out = "";
        foreach (myMessages as myMessage) {
            myMessage = myOptions + myMessage;
            $out ~= _View.element(myMessage["element"], myMessage);
        }

        return $out;
    }

    /**
     * Event listeners.
     *
     * @return array<string, mixed>
     */
    array implementedEvents() {
        return [];
    }
}
