


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.databases.Log;

import uim.cake.Log\Engine\BaseLog;
import uim.cake.Log\Log;

/**
 * This class is a bridge used to write LoggedQuery objects into a real log.
 * by default this class use the built-in CakePHP Log class to accomplish this
 *
 * @internal
 */
class QueryLogger : BaseLog
{
    /**
     * Constructor.
     *
     * @param array<string, mixed> $config Configuration array
     */
    public this(array $config = []) {
        _defaultConfig['scopes'] = ['queriesLog'];
        _defaultConfig['connection'] = '';

        super(($config);
    }

    /**
     * @inheritDoc
     */
    function log($level, $message, array $context = []) {
        $context['scope'] = this.scopes() ?: ['queriesLog'];
        $context['connection'] = this.getConfig('connection');

        if ($context['query'] instanceof LoggedQuery) {
            $context = $context['query'].getContext() + $context;
            $message = 'connection={connection} duration={took} rows={numRows} ' . $message;
        }
        Log::write('debug', $message, $context);
    }
}
