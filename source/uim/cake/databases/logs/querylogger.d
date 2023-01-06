module uim.cake.databases.Log;

import uim.cake.logs.Engine\BaseLog;
import uim.cake.logs.Log;

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
     * @param array<string, mixed> aConfig Configuration array
     */
    this(Json aConfig = []) {
        _defaultConfig["scopes"] = ["queriesLog"];
        _defaultConfig["connection"] = "";

        super((aConfig);
    }


    function log($level, $message, array $context = []) {
        $context["scope"] = this.scopes() ?: ["queriesLog"];
        $context["connection"] = this.getConfig("connection");

        if ($context["query"] instanceof LoggedQuery) {
            $context = $context["query"].getContext() + $context;
            $message = "connection={connection} duration={took} rows={numRows} " ~ $message;
        }
        Log::write("debug", $message, $context);
    }
}
