/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.viewss.widgets;

@safe:
import uim.cake;

// Interface for input widgets.
interface IWidget {
  /**
    * Converts the myData into one or many HTML elements.
    *
    * @param array<string, mixed> myData The data to render.
    * @param uim.cake.views\Form\IContext $context The current form context.
    * @return string Generated HTML for the widget element.
    */
  string render(array myData, IContext $context);

  /**
    * Returns a list of fields that need to be secured for this widget.
    *
    * @param array<string, mixed> myData The data to render.
    * @return Array of fields to secure.
    */
  string[] secureFields(array myData);
}
