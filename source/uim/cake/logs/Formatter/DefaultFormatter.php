

/**
 * CakePHP(tm) :  Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakefoundation.org CakePHP(tm) Project
 * @since         4.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cakegs\Formatter;

class DefaultFormatter : AbstractFormatter
{
    /**
     * Default config for this class
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [
        'dateFormat' => 'Y-m-d H:i:s',
        'includeTags' => false,
        'includeDate' => true,
    ];

    /**
     * @param array<string, mixed> myConfig Formatter config
     */
    this(array myConfig = []) {
        this.setConfig(myConfig);
    }


    function format($level, string myMessage, array $context = []): string
    {
        if (this._config['includeDate']) {
            myMessage = sprintf('%s %s: %s', date(this._config['dateFormat']), $level, myMessage);
        } else {
            myMessage = sprintf('%s: %s', $level, myMessage);
        }
        if (this._config['includeTags']) {
            myMessage = sprintf('<%s>%s</%s>', $level, myMessage, $level);
        }

        return myMessage;
    }
}
