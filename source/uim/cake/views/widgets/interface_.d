module uim.cake.views.widgets;

@safe:
import uim.cake;

// Interface for input widgets.
interface IWidget {
  /**
    * Converts the myData into one or many HTML elements.
    *
    * @param array<string, mixed> myData The data to render.
    * @param uim.cake.View\Form\IContext $context The current form context.
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
