


 *

 * @copyright     Copyright (c) 2017 Aura for PHP

 * @since         4.2.0
  */
module uim.cake.I18n;

/**
 * Formatter Interface
 */
interface FormatterInterface
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
    function format(string $locale, string $message, array $tokenValues): string;
}
