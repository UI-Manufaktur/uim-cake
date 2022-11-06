

/**
 * CakePHP(tm) :  Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakefoundation.org CakePHP(tm) Project
 * @since         4.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cakegs\Formatter;

/**
 * @deprecated 4.3.0 Create a custom formatter and set it with `formatter` config instead.
 */
class LegacySyslogFormatter : AbstractFormatter
{
    /**
     * Default config for this class
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [
        'format' => '%s: %s',
    ];

    /**
     * @param array<string, mixed> myConfig Formatter config
     */
    this(array myConfig = []) {
        this.setConfig(myConfig);
    }


    function format($level, string myMessage, array $context = []): string
    {
        return sprintf(this.getConfig('format'), $level, myMessage);
    }
}
