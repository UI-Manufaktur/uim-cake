


 *


 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.View\Widget;

import uim.cake.View\Form\ContextInterface;

/**
 * Interface for input widgets.
 */
interface WidgetInterface
{
    /**
     * Converts the $data into one or many HTML elements.
     *
     * @param array<string, mixed> $data The data to render.
     * @param uim.cake.View\Form\ContextInterface $context The current form context.
     * @return string Generated HTML for the widget element.
     */
    function render(array $data, ContextInterface $context): string;

    /**
     * Returns a list of fields that need to be secured for this widget.
     *
     * @param array<string, mixed> $data The data to render.
     * @return array<string> Array of fields to secure.
     */
    string[] secureFields(array $data): array;
}
