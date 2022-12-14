module uim.cake.I18n\Formatter;

import uim.cake.I18n\IFormatter;

/**
 * A formatter that will interpolate variables using sprintf and
 * select the correct plural form when required
 */
class SprintfFormatter : IFormatter {
    /**
     * Returns a string with all passed variables interpolated into the original
     * message. Variables are interpolated using the sprintf format.
     *
     * @param string $locale The locale in which the message is presented.
     * @param string $message The message to be translated
     * @param array $tokenValues The list of values to interpolate in the message
     * @return string The formatted message
     */
    string format(string $locale, string $message, array $tokenValues) {
        return vsprintf($message, $tokenValues);
    }
}
