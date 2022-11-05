module uim.baklava.View\Widget;

import uim.baklava.View\Form\IContext;

/**
 * Interface for input widgets.
 */
interface WidgetInterface
{
    /**
     * Converts the myData into one or many HTML elements.
     *
     * @param array<string, mixed> myData The data to render.
     * @param \Cake\View\Form\IContext $context The current form context.
     * @return string Generated HTML for the widget element.
     */
    function render(array myData, IContext $context): string;

    /**
     * Returns a list of fields that need to be secured for this widget.
     *
     * @param array<string, mixed> myData The data to render.
     * @return array<string> Array of fields to secure.
     */
    function secureFields(array myData): array;
}
