


 *


 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.I18n\Formatter;

import uim.cake.I18n\FormatterInterface;

/**
 * A formatter that will interpolate variables using sprintf and
 * select the correct plural form when required
 */
class SprintfFormatter : FormatterInterface
{
    /**
     * Returns a string with all passed variables interpolated into the original
     * message. Variables are interpolated using the sprintf format.
     *
     * @param string $locale The locale in which the message is presented.
     * @param string $message The message to be translated
     * @param array $tokenValues The list of values to interpolate in the message
     * @return string The formatted message
     */
    function format(string $locale, string $message, array $tokenValues): string
    {
        return vsprintf($message, $tokenValues);
    }
}
