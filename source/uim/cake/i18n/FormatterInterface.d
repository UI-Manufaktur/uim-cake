

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @copyright     Copyright (c) 2017 Aura for PHP
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         4.2.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake8n;

/**
 * Formatter Interface
 */
interface IFormatter
{
    /**
     * Returns a string with all passed variables interpolated into the original
     * message. Variables are interpolated using the sprintf format.
     *
     * @param string $locale The locale in which the message is presented.
     * @param string myMessage The message to be translated
     * @param array $tokenValues The list of values to interpolate in the message
     * @return string The formatted message
     */
    function format(string $locale, string myMessage, array $tokenValues): string;
}
