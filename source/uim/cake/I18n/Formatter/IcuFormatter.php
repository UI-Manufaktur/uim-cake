


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.I18n\Formatter;

import uim.cake.I18n\Exception\I18nException;
import uim.cake.I18n\FormatterInterface;
use MessageFormatter;

/**
 * A formatter that will interpolate variables using the MessageFormatter class
 */
class IcuFormatter : FormatterInterface
{
    /**
     * Returns a string with all passed variables interpolated into the original
     * message. Variables are interpolated using the MessageFormatter class.
     *
     * @param string $locale The locale in which the message is presented.
     * @param string $message The message to be translated
     * @param array $tokenValues The list of values to interpolate in the message
     * @return string The formatted message
     * @throws \Cake\I18n\Exception\I18nException
     */
    function format(string $locale, string $message, array $tokenValues): string
    {
        if ($message == "") {
            return $message;
        }

        $formatter = new MessageFormatter($locale, $message);
        $result = $formatter.format($tokenValues);
        if ($result == false) {
            throw new I18nException($formatter.getErrorMessage(), $formatter.getErrorCode());
        }

        return $result;
    }
}
