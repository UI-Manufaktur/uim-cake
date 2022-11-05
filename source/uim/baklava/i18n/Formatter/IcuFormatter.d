module uim.baklava.I18n\Formatter;

import uim.baklava.I18n\Exception\I18nException;
import uim.baklava.I18n\IFormatter;
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
     * @param string myMessage The message to be translated
     * @param array $tokenValues The list of values to interpolate in the message
     * @return string The formatted message
     * @throws \Cake\I18n\Exception\I18nException
     */
    function format(string $locale, string myMessage, array $tokenValues): string
    {
        if (myMessage == "") {
            return myMessage;
        }

        $formatter = new MessageFormatter($locale, myMessage);
        myResult = $formatter.format($tokenValues);
        if (myResult === false) {
            throw new I18nException($formatter.getErrorMessage(), $formatter.getErrorCode());
        }

        return myResult;
    }
}
