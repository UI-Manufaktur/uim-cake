module uim.baklava.databases.Log;

import uim.baklava.Log\Engine\BaseLog;
import uim.baklava.Log\Log;

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
     * @param array<string, mixed> myConfig Configuration array
     */
    this(array myConfig = []) {
        this._defaultConfig['scopes'] = ['queriesLog'];
        this._defaultConfig['connection'] = '';

        super.this(myConfig);
    }


    function log($level, myMessage, array $context = []) {
        $context['scope'] = this.scopes() ?: ['queriesLog'];
        $context['connection'] = this.getConfig('connection');

        if ($context['query'] instanceof LoggedQuery) {
            $context = $context['query'].getContext() + $context;
            myMessage = 'connection={connection} duration={took} rows={numRows} ' . myMessage;
        }
        Log::write('debug', myMessage, $context);
    }
}
