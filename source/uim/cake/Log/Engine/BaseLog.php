

/**
 * CakePHP(tm) :  Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakefoundation.org CakePHP(tm) Project
 * @since         2.2.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.Log\Engine;

use ArrayObject;
import uim.baklava.core.InstanceConfigTrait;
import uim.baklava.Log\Formatter\AbstractFormatter;
import uim.baklava.Log\Formatter\DefaultFormatter;
use InvalidArgumentException;
use JsonSerializable;
use Psr\Log\AbstractLogger;
use Serializable;

/**
 * Base log engine class.
 */
abstract class BaseLog : AbstractLogger
{
    use InstanceConfigTrait;

    /**
     * Default config for this class
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [
        'levels' => [],
        'scopes' => [],
        'formatter' => DefaultFormatter::class,
    ];

    /**
     * @var \Cake\Log\Formatter\AbstractFormatter
     */
    protected $formatter;

    /**
     * __construct method
     *
     * @param array<string, mixed> myConfig Configuration array
     */
    this(array myConfig = []) {
        this.setConfig(myConfig);

        if (!is_array(this._config['scopes']) && this._config['scopes'] !== false) {
            this._config['scopes'] = (array)this._config['scopes'];
        }

        if (!is_array(this._config['levels'])) {
            this._config['levels'] = (array)this._config['levels'];
        }

        if (!empty(this._config['types']) && empty(this._config['levels'])) {
            this._config['levels'] = (array)this._config['types'];
        }

        $formatter = this._config['formatter'] ?? DefaultFormatter::class;
        if (!is_object($formatter)) {
            if (is_array($formatter)) {
                myClass = $formatter['className'];
                myOptions = $formatter;
            } else {
                myClass = $formatter;
                myOptions = [];
            }
            /** @var class-string<\Cake\Log\Formatter\AbstractFormatter> myClass */
            $formatter = new myClass(myOptions);
        }

        if (!$formatter instanceof AbstractFormatter) {
            throw new InvalidArgumentException(sprintf(
                'Formatter must extend `%s`, got `%s` instead',
                AbstractFormatter::class,
                get_class($formatter)
            ));
        }
        this.formatter = $formatter;
    }

    /**
     * Get the levels this logger is interested in.
     *
     * @return array<string>
     */
    function levels(): array
    {
        return this._config['levels'];
    }

    /**
     * Get the scopes this logger is interested in.
     *
     * @return array<string>|false
     */
    function scopes() {
        return this._config['scopes'];
    }

    /**
     * Formats the message to be logged.
     *
     * The context can optionally be used by log engines to interpolate variables
     * or add additional info to the logged message.
     *
     * @param string myMessage The message to be formatted.
     * @param array $context Additional logging information for the message.
     * @return string
     * @deprecated 4.3.0 Call `interpolate()` directly from your log engine and format the message in a formatter.
     */
    protected auto _format(string myMessage, array $context = []): string
    {
        return this.interpolate(myMessage, $context);
    }

    /**
     * Replaces placeholders in message string with context values.
     *
     * @param string myMessage Formatted string
     * @param array $context Context for placeholder values.
     * @return string
     */
    protected auto interpolate(string myMessage, array $context = []): string
    {
        if (strpos(myMessage, '{') === false && strpos(myMessage, '}') === false) {
            return myMessage;
        }

        preg_match_all(
            '/(?<!' . preg_quote('\\', '/') . ')\{([a-z0-9-_]+)\}/i',
            myMessage,
            $matches
        );
        if (empty($matches)) {
            return myMessage;
        }

        $placeholders = array_intersect($matches[1], array_keys($context));
        $replacements = [];

        foreach ($placeholders as myKey) {
            myValue = $context[myKey];

            if (is_scalar(myValue)) {
                $replacements['{' . myKey . '}'] = (string)myValue;
                continue;
            }

            if (is_array(myValue)) {
                $replacements['{' . myKey . '}'] = json_encode(myValue, JSON_UNESCAPED_UNICODE);
                continue;
            }

            if (myValue instanceof JsonSerializable) {
                $replacements['{' . myKey . '}'] = json_encode(myValue, JSON_UNESCAPED_UNICODE);
                continue;
            }

            if (myValue instanceof ArrayObject) {
                $replacements['{' . myKey . '}'] = json_encode(myValue.getArrayCopy(), JSON_UNESCAPED_UNICODE);
                continue;
            }

            if (myValue instanceof Serializable) {
                $replacements['{' . myKey . '}'] = myValue.serialize();
                continue;
            }

            if (is_object(myValue)) {
                if (method_exists(myValue, 'toArray')) {
                    $replacements['{' . myKey . '}'] = json_encode(myValue.toArray(), JSON_UNESCAPED_UNICODE);
                    continue;
                }

                if (method_exists(myValue, '__serialize')) {
                    $replacements['{' . myKey . '}'] = serialize(myValue);
                    continue;
                }

                if (method_exists(myValue, '__toString')) {
                    $replacements['{' . myKey . '}'] = (string)myValue;
                    continue;
                }

                if (method_exists(myValue, '__debugInfo')) {
                    $replacements['{' . myKey . '}'] = json_encode(myValue.__debugInfo(), JSON_UNESCAPED_UNICODE);
                    continue;
                }
            }

            $replacements['{' . myKey . '}'] = sprintf('[unhandled value of type %s]', getTypeName(myValue));
        }

        /** @psalm-suppress InvalidArgument */
        return str_replace(array_keys($replacements), $replacements, myMessage);
    }
}
