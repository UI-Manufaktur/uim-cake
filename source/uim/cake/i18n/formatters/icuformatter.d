module uim.cake.I18n\Formatter;

import uim.cake.I18n\exceptions.I18nException;
import uim.cake.I18n\IFormatter;
use MessageFormatter;

/**
 * A formatter that will interpolate variables using the MessageFormatter class
 */
class IcuFormatter : IFormatter
{
    /**
     * Returns a string with all passed variables interpolated into the original
     * message. Variables are interpolated using the MessageFormatter class.
     *
     * @param string $locale The locale in which the message is presented.
     * @param string $message The message to be translated
     * @param array $tokenValues The list of values to interpolate in the message
     * @return string The formatted message
     * @throws uim.cake.I18n\exceptions.I18nException
     */
    string format(string $locale, string $message, array $tokenValues) {
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
