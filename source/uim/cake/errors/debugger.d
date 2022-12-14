module uim.cake.errors;

import uim.cake.core.Configure;
import uim.cake.core.InstanceConfigTrait;
import uim.cake.errors\Debug\ArrayItemNode;
import uim.cake.errors\Debug\ArrayNode;
import uim.cake.errors\Debug\ClassNode;
import uim.cake.errors\Debug\ConsoleFormatter;
import uim.cake.errors\Debug\DebugContext;
import uim.cake.errors\Debug\IFormatter;
import uim.cake.errors\Debug\HtmlFormatter;
import uim.cake.errors\Debug\INode;
import uim.cake.errors\Debug\PropertyNode;
import uim.cake.errors\Debug\ReferenceNode;
import uim.cake.errors\Debug\ScalarNode;
import uim.cake.errors\Debug\SpecialNode;
import uim.cake.errors\Debug\TextFormatter;
import uim.cakegs\Log;
import uim.cakeilities.Hash;
import uim.cakeilities.Security;
import uim.cakeilities.Text;
use Closure;
use Exception;
use InvalidArgumentException;
use ReflectionObject;
use ReflectionProperty;
use RuntimeException;
use Throwable;

/**
 * Provide custom logging and error handling.
 *
 * Debugger : PHP"s default error handling and gives
 * simpler to use more powerful interfaces.
 *
 * @link https://book.UIM.org/4/en/development/debugging.html#module-Cake\Error
 */
class Debugger
{
    use InstanceConfigTrait;

    /**
     * Default configuration
     *
     * @var array<string, mixed>
     */
    protected STRINGAA _defaultConfig = [
        "outputMask":[],
        "exportFormatter":null,
        "editor":"phpstorm",
    ];

    /**
     * The current output format.
     */
    protected string $_outputFormat = "js";

    /**
     * Templates used when generating trace or error strings. Can be global or indexed by the format
     * value used in $_outputFormat.
     *
     * @var array<string, array<string, mixed>>
     */
    protected $_templates = [
        "log":[
            "trace":"{:reference} - {:path}, line {:line}",
            "error":"{:error} ({:code}): {:description} in [{:file}, line {:line}]",
        ],
        "js":[
            "error":"",
            "info":"",
            "trace":"<pre class="stack-trace">{:trace}</pre>",
            "code":"",
            "context":"",
            "links":[],
            "escapeContext":true,
        ],
        "html":[
            "trace":"<pre class="cake-error trace"><b>Trace</b> <p>{:trace}</p></pre>",
            "context":"<pre class="cake-error context"><b>Context</b> <p>{:context}</p></pre>",
            "escapeContext":true,
        ],
        "txt":[
            "error":"{:error}: {:code} :: {:description} on line {:line} of {:path}\n{:info}",
            "code":"",
            "info":"",
        ],
        "base":[
            "traceLine":"{:reference} - {:path}, line {:line}",
            "trace":"Trace:\n{:trace}\n",
            "context":"Context:\n{:context}\n",
        ],
    ];

    /**
     * A map of editors to their link templates.
     *
     * @var array<string, string|callable>
     */
    protected $editors = [
        "atom":"atom://core/open/file?filename={file}&line={line}",
        "emacs":"emacs://open?url=file://{file}&line={line}",
        "macvim":"mvim://open/?url=file://{file}&line={line}",
        "phpstorm":"phpstorm://open?file={file}&line={line}",
        "sublime":"subl://open?url=file://{file}&line={line}",
        "textmate":"txmt://open?url=file://{file}&line={line}",
        "vscode":"vscode://file/{file}:{line}",
    ];

    /**
     * Holds current output data when outputFormat is false.
     *
     * @var array
     */
    protected $_data = [];

    /**
     * Constructor.
     */
    this() {
        $docRef = ini_get("docref_root");
        if (empty($docRef) && function_exists("ini_set")) {
            ini_set("docref_root", "https://secure.php.net/");
        }
        if (!defined("E_RECOVERABLE_ERROR")) {
            define("E_RECOVERABLE_ERROR", 4096);
        }

        myConfig = array_intersect_key((array)Configure::read("Debugger"), this._defaultConfig);
        this.setConfig(myConfig);

        $e = "<pre class="cake-error">";
        $e .= "<a href="javascript:void(0);" onclick="document.getElementById(\"{:id}-trace\")";
        $e .= ".style.display = (document.getElementById(\"{:id}-trace\").style.display == ";
        $e .= "\"none\" ? \"\" : \"none\");"><b>{:error}</b> ({:code})</a>: {:description} ";
        $e .= "[<b>{:path}</b>, line <b>{:line}</b>]";

        $e .= "<div id="{:id}-trace" class="cake-stack-trace" style="display: none;">";
        $e .= "{:links}{:info}</div>";
        $e .= "</pre>";
        this._templates["js"]["error"] = $e;

        $t = "<div id="{:id}-trace" class="cake-stack-trace" style="display: none;">";
        $t .= "{:context}{:code}{:trace}</div>";
        this._templates["js"]["info"] = $t;

        $links = [];
        $link = "<a href="javascript:void(0);" onclick="document.getElementById(\"{:id}-code\")";
        $link .= ".style.display = (document.getElementById(\"{:id}-code\").style.display == ";
        $link .= "\"none\" ? \"\" : \"none\")">Code</a>";
        $links["code"] = $link;

        $link = "<a href="javascript:void(0);" onclick="document.getElementById(\"{:id}-context\")";
        $link .= ".style.display = (document.getElementById(\"{:id}-context\").style.display == ";
        $link .= "\"none\" ? \"\" : \"none\")">Context</a>";
        $links["context"] = $link;

        this._templates["js"]["links"] = $links;

        this._templates["js"]["context"] = "<pre id="{:id}-context" class="cake-context cake-debug" ";
        this._templates["js"]["context"] .= "style="display: none;">{:context}</pre>";

        this._templates["js"]["code"] = "<pre id="{:id}-code" class="cake-code-dump" ";
        this._templates["js"]["code"] .= "style="display: none;">{:code}</pre>";

        $e = "<pre class="cake-error"><b>{:error}</b> ({:code}) : {:description} ";
        $e .= "[<b>{:path}</b>, line <b>{:line}]</b></pre>";
        this._templates["html"]["error"] = $e;

        this._templates["html"]["context"] = "<pre class="cake-context cake-debug"><b>Context</b> ";
        this._templates["html"]["context"] .= "<p>{:context}</p></pre>";
    }

    /**
     * Returns a reference to the Debugger singleton object instance.
     *
     * @param string|null myClass Class name.
     * @return static
     */
    static auto getInstance(Nullable!string myClass = null) {
        static $instance = [];
        if (!empty(myClass)) {
            if (!$instance || strtolower(myClass) !== strtolower(get_class($instance[0]))) {
                $instance[0] = new myClass();
            }
        }
        if (!$instance) {
            $instance[0] = new Debugger();
        }

        return $instance[0];
    }

    /**
     * Read or write configuration options for the Debugger instance.
     *
     * @param array<string, mixed>|string|null myKey The key to get/set, or a complete array of configs.
     * @param mixed|null myValue The value to set.
     * @param bool myMerge Whether to recursively merge or overwrite existing config, defaults to true.
     * @return mixed Config value being read, or the object itself on write operations.
     * @throws \Cake\Core\Exception\CakeException When trying to set a key that is invalid.
     */
    static function configInstance(myKey = null, myValue = null, bool myMerge = true) {
        if (myKey == null) {
            return static::getInstance().getConfig(myKey);
        }

        if (is_array(myKey) || func_num_args() >= 2) {
            return static::getInstance().setConfig(myKey, myValue, myMerge);
        }

        return static::getInstance().getConfig(myKey);
    }

    /**
     * Reads the current output masking.
     */
    static STRINGAA outputMask() {
        return static::configInstance("outputMask");
    }

    /**
     * Sets configurable masking of debugger output by property name and array key names.
     *
     * ### Example
     *
     * Debugger::setOutputMask(["password":"[*************]");
     *
     * @param array<string, string> myValue An array where keys are replaced by their values in output.
     * @param bool myMerge Whether to recursively merge or overwrite existing config, defaults to true.
     * @return void
     */
    static auto setOutputMask(array myValue, bool myMerge = true): void
    {
        static::configInstance("outputMask", myValue, myMerge);
    }

    /**
     * Add an editor link format
     *
     * Template strings can use the `{file}` and `{line}` placeholders.
     * Closures templates must return a string, and accept two parameters:
     * The file and line.
     *
     * @param string myName The name of the editor.
     * @param \Closure|string myTemplate The string template or closure
     * @return void
     */
    static function addEditor(string myName, myTemplate): void
    {
        $instance = static::getInstance();
        if (!is_string(myTemplate) && !(myTemplate instanceof Closure)) {
            myType = getTypeName(myTemplate);
            throw new RuntimeException("Invalid editor type of `{myType}`. Expected string or Closure.");
        }
        $instance.editors[myName] = myTemplate;
    }

    /**
     * Choose the editor link style you want to use.
     *
     * @param string myName The editor name.
     * @return void
     */
    static auto setEditor(string myName): void
    {
        $instance = static::getInstance();
        if (!isset($instance.editors[myName])) {
            $known = implode(", ", array_keys($instance.editors));
            throw new RuntimeException("Unknown editor `{myName}`. Known editors are {$known}");
        }
        $instance.setConfig("editor", myName);
    }

    /**
     * Get a formatted URL for the active editor.
     *
     * @param string myfile The file to create a link for.
     * @param int $line The line number to create a link for.
     * @return The formatted URL.
     */
    static string editorUrl(string myfile, int $line) {
        $instance = static::getInstance();
        $editor = $instance.getConfig("editor");
        if (!isset($instance.editors[$editor])) {
            throw new RuntimeException("Cannot format editor URL `{$editor}` is not a known editor.");
        }

        myTemplate = $instance.editors[$editor];
        if (is_string(myTemplate)) {
            return str_replace(["{file}", "{line}"], [myfile, (string)$line], myTemplate);
        }

        return myTemplate(myfile, $line);
    }

    /**
     * Recursively formats and outputs the contents of the supplied variable.
     *
     * @param mixed $var The variable to dump.
     * @param int $maxDepth The depth to output to. Defaults to 3.
     * @return void
     * @see \Cake\Error\Debugger::exportVar()
     * @link https://book.UIM.org/4/en/development/debugging.html#outputting-values
     */
    static function dump($var, int $maxDepth = 3): void
    {
        pr(static::exportVar($var, $maxDepth));
    }

    /**
     * Creates an entry in the log file. The log entry will contain a stack trace from where it was called.
     * as well as export the variable using exportVar. By default, the log is written to the debug log.
     *
     * @param mixed $var Variable or content to log.
     * @param string|int $level Type of log to use. Defaults to "debug".
     * @param int $maxDepth The depth to output to. Defaults to 3.
     * @return void
     */
    static function log($var, $level = "debug", int $maxDepth = 3): void
    {
        /** @var string $source */
        $source = static::trace(["start":1]);
        $source .= "\n";

        Log::write(
            $level,
            "\n" . $source . static::exportVarAsPlainText($var, $maxDepth)
        );
    }

    /**
     * Outputs a stack trace based on the supplied options.
     *
     * ### Options
     *
     * - `depth` - The number of stack frames to return. Defaults to 999
     * - `format` - The format you want the return. Defaults to the currently selected format. If
     *    format is "array" or "points" the return will be an array.
     * - `args` - Should arguments for functions be shown? If true, the arguments for each method call
     *   will be displayed.
     * - `start` - The stack frame to start generating a trace from. Defaults to 0
     *
     * @param array<string, mixed> myOptions Format for outputting stack trace.
     * @return array|string Formatted stack trace.
     * @link https://book.UIM.org/4/en/development/debugging.html#generating-stack-traces
     */
    static function trace(array myOptions = []) {
        return Debugger::formatTrace(debug_backtrace(), myOptions);
    }

    /**
     * Formats a stack trace based on the supplied options.
     *
     * ### Options
     *
     * - `depth` - The number of stack frames to return. Defaults to 999
     * - `format` - The format you want the return. Defaults to the currently selected format. If
     *    format is "array" or "points" the return will be an array.
     * - `args` - Should arguments for functions be shown? If true, the arguments for each method call
     *   will be displayed.
     * - `start` - The stack frame to start generating a trace from. Defaults to 0
     *
     * @param \Throwable|array $backtrace Trace as array or an exception object.
     * @param array<string, mixed> myOptions Format for outputting stack trace.
     * @return array|string Formatted stack trace.
     * @link https://book.UIM.org/4/en/development/debugging.html#generating-stack-traces
     */
    static function formatTrace($backtrace, array myOptions = []) {
        if ($backtrace instanceof Throwable) {
            $backtrace = $backtrace.getTrace();
        }
        $self = Debugger::getInstance();
        $defaults = [
            "depth":999,
            "format":$self._outputFormat,
            "args":false,
            "start":0,
            "scope":null,
            "exclude":["call_user_func_array", "trigger_error"],
        ];
        myOptions = Hash::merge($defaults, myOptions);

        myCount = count($backtrace);
        $back = [];

        $_trace = [
            "line":"??",
            "file":"[internal]",
            "class":null,
            "function":"[main]",
        ];

        for ($i = myOptions["start"]; $i < myCount && $i < myOptions["depth"]; $i++) {
            $trace = $backtrace[$i] + ["file":"[internal]", "line":"??"];
            $signature = $reference = "[main]";

            if (isset($backtrace[$i + 1])) {
                $next = $backtrace[$i + 1] + $_trace;
                $signature = $reference = $next["function"];

                if (!empty($next["class"])) {
                    $signature = $next["class"] . "::" . $next["function"];
                    $reference = $signature . "(";
                    if (myOptions["args"] && isset($next["args"])) {
                        $args = [];
                        foreach ($next["args"] as $arg) {
                            $args[] = Debugger::exportVar($arg);
                        }
                        $reference .= implode(", ", $args);
                    }
                    $reference .= ")";
                }
            }
            if (in_array($signature, myOptions["exclude"], true)) {
                continue;
            }
            if (myOptions["format"] == "points" && $trace["file"] !== "[internal]") {
                $back[] = ["file":$trace["file"], "line":$trace["line"]];
            } elseif (myOptions["format"] == "array") {
                $back[] = $trace;
            } else {
                if (isset($self._templates[myOptions["format"]]["traceLine"])) {
                    $tpl = $self._templates[myOptions["format"]]["traceLine"];
                } else {
                    $tpl = $self._templates["base"]["traceLine"];
                }
                $trace["path"] = static::trimPath($trace["file"]);
                $trace["reference"] = $reference;
                unset($trace["object"], $trace["args"]);
                $back[] = Text::insert($tpl, $trace, ["before":"{:", "after":"}"]);
            }
        }

        if (myOptions["format"] == "array" || myOptions["format"] == "points") {
            return $back;
        }

        /** @psalm-suppress InvalidArgument */
        return implode("\n", $back);
    }

    /**
     * Shortens file paths by replacing the application base path with "APP", and the UIM core
     * path with "CORE".
     *
     * @param string myPath Path to shorten.
     * @return string Normalized path
     */
    static string trimPath(string myPath) {
        if (defined("APP") && strpos(myPath, APP) == 0) {
            return str_replace(APP, "APP/", myPath);
        }
        if (defined("CAKE_CORE_INCLUDE_PATH") && strpos(myPath, CAKE_CORE_INCLUDE_PATH) == 0) {
            return str_replace(CAKE_CORE_INCLUDE_PATH, "CORE", myPath);
        }
        if (defined("ROOT") && strpos(myPath, ROOT) == 0) {
            return str_replace(ROOT, "ROOT", myPath);
        }

        return myPath;
    }

    /**
     * Grabs an excerpt from a file and highlights a given line of code.
     *
     * Usage:
     *
     * ```
     * Debugger::excerpt("/path/to/file", 100, 4);
     * ```
     *
     * The above would return an array of 8 items. The 4th item would be the provided line,
     * and would be wrapped in `<span class="code-highlight"></span>`. All the lines
     * are processed with highlight_string() as well, so they have basic PHP syntax highlighting
     * applied.
     *
     * @param string myfile Absolute path to a PHP file.
     * @param int $line Line number to highlight.
     * @param int $context Number of lines of context to extract above and below $line.
     * @return Set of lines highlighted
     * @see https://secure.php.net/highlight_string
     * @link https://book.UIM.org/4/en/development/debugging.html#getting-an-excerpt-from-a-file
     */
    static string[] excerpt(string myfile, int $line, int $context = 2) {
        $lines = [];
        if (!file_exists(myfile)) {
            return [];
        }
        myData = file_get_contents(myfile);
        if (empty(myData)) {
            return $lines;
        }
        if (strpos(myData, "\n") !== false) {
            myData = explode("\n", myData);
        }
        $line--;
        if (!isset(myData[$line])) {
            return $lines;
        }
        for ($i = $line - $context; $i < $line + $context + 1; $i++) {
            if (!isset(myData[$i])) {
                continue;
            }
            $string = str_replace(["\r\n", "\n"], "", static::_highlight(myData[$i]));
            if ($i == $line) {
                $lines[] = "<span class="code-highlight">" . $string . "</span>";
            } else {
                $lines[] = $string;
            }
        }

        return $lines;
    }

    /**
     * Wraps the highlight_string function in case the server API does not
     * implement the function as it is the case of the HipHop interpreter
     *
     * @param string $str The string to convert.
     * @return string
     */
    protected static string _highlight(string $str) {
        if (function_exists("hphp_log") || function_exists("hphp_gettid")) {
            return htmlentities($str);
        }
        $added = false;
        if (strpos($str, "<?php") == false) {
            $added = true;
            $str = "<?php \n" . $str;
        }
        $highlight = highlight_string($str, true);
        if ($added) {
            $highlight = str_replace(
                ["&lt;?php&nbsp;<br/>", "&lt;?php&nbsp;<br />"],
                "",
                $highlight
            );
        }

        return $highlight;
    }

    /**
     * Get the configured export formatter or infer one based on the environment.
     *
     * @return \Cake\Error\Debug\IFormatter
     * @unstable This method is not stable and may change in the future.
     * @since 4.1.0
     */
    auto getExportFormatter(): IFormatter
    {
        $instance = static::getInstance();
        myClass = $instance.getConfig("exportFormatter");
        if (!myClass) {
            if (ConsoleFormatter::environmentMatches()) {
                myClass = ConsoleFormatter::class;
            } elseif (HtmlFormatter::environmentMatches()) {
                myClass = HtmlFormatter::class;
            } else {
                myClass = TextFormatter::class;
            }
        }
        $instance = new myClass();
        if (!$instance instanceof IFormatter) {
            throw new RuntimeException(
                "The `{myClass}` formatter does not implement " . IFormatter::class
            );
        }

        return $instance;
    }

    /**
     * Converts a variable to a string for debug output.
     *
     * *Note:* The following keys will have their contents
     * replaced with `*****`:
     *
     *  - password
     *  - login
     *  - host
     *  - database
     *  - port
     *  - prefix
     *  - schema
     *
     * This is done to protect database credentials, which could be accidentally
     * shown in an error message if UIM is deployed in development mode.
     *
     * @param mixed $var Variable to convert.
     * @param int $maxDepth The depth to output to. Defaults to 3.
     * @return Variable as a formatted string
     */
    static string exportVar($var, int $maxDepth = 3) {
        $context = new DebugContext($maxDepth);
        myNode = static::export($var, $context);

        return static::getInstance().getExportFormatter().dump(myNode);
    }

    /**
     * Converts a variable to a plain text string.
     *
     * @param mixed $var Variable to convert.
     * @param int $maxDepth The depth to output to. Defaults to 3.
     * @return string Variable as a string
     */
    static string exportVarAsPlainText($var, int $maxDepth = 3) {
        return (new TextFormatter()).dump(
            static::export($var, new DebugContext($maxDepth))
        );
    }

    /**
     * Convert the variable to the internal node tree.
     *
     * The node tree can be manipulated and serialized more easily
     * than many object graphs can.
     *
     * @param mixed $var Variable to convert.
     * @param int $maxDepth The depth to generate nodes to. Defaults to 3.
     * @return \Cake\Error\Debug\INode The root node of the tree.
     */
    static function exportVarAsNodes($var, int $maxDepth = 3): INode
    {
        return static::export($var, new DebugContext($maxDepth));
    }

    /**
     * Protected export function used to keep track of indentation and recursion.
     *
     * @param mixed $var The variable to dump.
     * @param \Cake\Error\Debug\DebugContext $context Dump context
     * @return \Cake\Error\Debug\INode The dumped variable.
     */
    protected static function export($var, DebugContext $context): INode
    {
        myType = static::getType($var);
        switch (myType) {
            case "float":
            case "string":
            case "resource":
            case "resource (closed)":
            case "null":
                return new ScalarNode(myType, $var);
            case "boolean":
                return new ScalarNode("bool", $var);
            case "integer":
                return new ScalarNode("int", $var);
            case "array":
                return static::exportArray($var, $context.withAddedDepth());
            case "unknown":
                return new SpecialNode("(unknown)");
            default:
                return static::exportObject($var, $context.withAddedDepth());
        }
    }

    /**
     * Export an array type object. Filters out keys used in datasource configuration.
     *
     * The following keys are replaced with ***"s
     *
     * - password
     * - login
     * - host
     * - database
     * - port
     * - prefix
     * - schema
     *
     * @param array $var The array to export.
     * @param \Cake\Error\Debug\DebugContext $context The current dump context.
     * @return \Cake\Error\Debug\ArrayNode Exported array.
     */
    protected static function exportArray(array $var, DebugContext $context): ArrayNode
    {
        myItems = [];

        $remaining = $context.remainingDepth();
        if ($remaining >= 0) {
            $outputMask = static::outputMask();
            foreach ($var as myKey: $val) {
                if (array_key_exists(myKey, $outputMask)) {
                    myNode = new ScalarNode("string", $outputMask[myKey]);
                } elseif ($val !== $var) {
                    // Dump all the items without increasing depth.
                    myNode = static::export($val, $context);
                } else {
                    // Likely recursion, so we increase depth.
                    myNode = static::export($val, $context.withAddedDepth());
                }
                myItems[] = new ArrayItemNode(static::export(myKey, $context), myNode);
            }
        } else {
            myItems[] = new ArrayItemNode(
                new ScalarNode("string", ""),
                new SpecialNode("[maximum depth reached]")
            );
        }

        return new ArrayNode(myItems);
    }

    /**
     * Handles object to node conversion.
     *
     * @param object $var Object to convert.
     * @param \Cake\Error\Debug\DebugContext $context The dump context.
     * @return \Cake\Error\Debug\INode
     * @see \Cake\Error\Debugger::exportVar()
     */
    protected static function exportObject(object $var, DebugContext $context): INode
    {
        $isRef = $context.hasReference($var);
        $refNum = $context.getReferenceId($var);

        myClassName = get_class($var);
        if ($isRef) {
            return new ReferenceNode(myClassName, $refNum);
        }
        myNode = new ClassNode(myClassName, $refNum);

        $remaining = $context.remainingDepth();
        if ($remaining > 0) {
            if (method_exists($var, "__debugInfo")) {
                try {
                    foreach ($var.__debugInfo() as myKey: $val) {
                        myNode.addProperty(new PropertyNode(""{myKey}"", null, static::export($val, $context)));
                    }

                    return myNode;
                } catch (Exception $e) {
                    return new SpecialNode("(unable to export object: {$e.getMessage()})");
                }
            }

            $outputMask = static::outputMask();
            $objectVars = get_object_vars($var);
            foreach ($objectVars as myKey: myValue) {
                if (array_key_exists(myKey, $outputMask)) {
                    myValue = $outputMask[myKey];
                }
                /** @psalm-suppress RedundantCast */
                myNode.addProperty(
                    new PropertyNode((string)myKey, "public", static::export(myValue, $context.withAddedDepth()))
                );
            }

            $ref = new ReflectionObject($var);

            $filters = [
                ReflectionProperty::IS_PROTECTED: "protected",
                ReflectionProperty::IS_PRIVATE: "private",
            ];
            foreach ($filters as $filter: $visibility) {
                $reflectionProperties = $ref.getProperties($filter);
                foreach ($reflectionProperties as $reflectionProperty) {
                    $reflectionProperty.setAccessible(true);

                    if (
                        method_exists($reflectionProperty, "isInitialized") &&
                        !$reflectionProperty.isInitialized($var)
                    ) {
                        myValue = new SpecialNode("[uninitialized]");
                    } else {
                        myValue = static::export($reflectionProperty.getValue($var), $context.withAddedDepth());
                    }
                    myNode.addProperty(
                        new PropertyNode(
                            $reflectionProperty.getName(),
                            $visibility,
                            myValue
                        )
                    );
                }
            }
        }

        return myNode;
    }

    /**
     * Get the output format for Debugger error rendering.
     * @return Returns the current format when getting.
     */
    static string getOutputFormat() {
        return Debugger::getInstance()._outputFormat;
    }

    /**
     * Set the output format for Debugger error rendering.
     *
     * @param string $format The format you want errors to be output as.
     * @return void
     * @throws \InvalidArgumentException When choosing a format that doesn"t exist.
     */
    static auto setOutputFormat(string $format): void
    {
        $self = Debugger::getInstance();

        if (!isset($self._templates[$format])) {
            throw new InvalidArgumentException("Invalid Debugger output format.");
        }
        $self._outputFormat = $format;
    }

    /**
     * Add an output format or update a format in Debugger.
     *
     * ```
     * Debugger::addFormat("custom", myData);
     * ```
     *
     * Where myData is an array of strings that use Text::insert() variable
     * replacement. The template vars should be in a `{:id}` style.
     * An error formatter can have the following keys:
     *
     * - "error" - Used for the container for the error message. Gets the following template
     *   variables: `id`, `error`, `code`, `description`, `path`, `line`, `links`, `info`
     * - "info" - A combination of `code`, `context` and `trace`. Will be set with
     *   the contents of the other template keys.
     * - "trace" - The container for a stack trace. Gets the following template
     *   variables: `trace`
     * - "context" - The container element for the context variables.
     *   Gets the following templates: `id`, `context`
     * - "links" - An array of HTML links that are used for creating links to other resources.
     *   Typically this is used to create javascript links to open other sections.
     *   Link keys, are: `code`, `context`, `help`. See the JS output format for an
     *   example.
     * - "traceLine" - Used for creating lines in the stacktrace. Gets the following
     *   template variables: `reference`, `path`, `line`
     *
     * Alternatively if you want to use a custom callback to do all the formatting, you can use
     * the callback key, and provide a callable:
     *
     * ```
     * Debugger::addFormat("custom", ["callback":[$foo, "outputError"]];
     * ```
     *
     * The callback can expect two parameters. The first is an array of all
     * the error data. The second contains the formatted strings generated using
     * the other template strings. Keys like `info`, `links`, `code`, `context` and `trace`
     * will be present depending on the other templates in the format type.
     *
     * @param string $format Format to use, including "js" for JavaScript-enhanced HTML, "html" for
     *    straight HTML output, or "txt" for unformatted text.
     * @param array $strings Template strings, or a callback to be used for the output format.
     * @return array The resulting format string set.
     */
    static function addFormat(string $format, array $strings): array
    {
        $self = Debugger::getInstance();
        if (isset($self._templates[$format])) {
            if (isset($strings["links"])) {
                $self._templates[$format]["links"] = array_merge(
                    $self._templates[$format]["links"],
                    $strings["links"]
                );
                unset($strings["links"]);
            }
            $self._templates[$format] = $strings + $self._templates[$format];
        } else {
            $self._templates[$format] = $strings;
        }

        return $self._templates[$format];
    }

    /**
     * Takes a processed array of data from an error and displays it in the chosen format.
     *
     * @param array myData Data to output.
     * @return void
     */
    function outputError(array myData): void
    {
        $defaults = [
            "level":0,
            "error":0,
            "code":0,
            "description":"",
            "file":"",
            "line":0,
            "context":[],
            "start":2,
        ];
        myData += $defaults;

        myfiles = static::trace(["start":myData["start"], "format":"points"]);
        $code = "";
        myfile = null;
        if (isset(myfiles[0]["file"])) {
            myfile = myfiles[0];
        } elseif (isset(myfiles[1]["file"])) {
            myfile = myfiles[1];
        }
        if (myfile) {
            $code = static::excerpt(myfile["file"], myfile["line"], 1);
        }
        $trace = static::trace(["start":myData["start"], "depth":"20"]);
        $insertOpts = ["before":"{:", "after":"}"];
        $context = [];
        $links = [];
        $info = "";

        foreach ((array)myData["context"] as $var: myValue) {
            $context[] = "\${$var} = " . static::exportVar(myValue, 3);
        }

        switch (this._outputFormat) {
            case false:
                this._data[] = compact("context", "trace") + myData;

                return;
            case "log":
                static::log(compact("context", "trace") + myData);

                return;
        }

        myData["trace"] = $trace;
        myData["id"] = "cakeErr" . uniqid();
        $tpl = this._templates[this._outputFormat] + this._templates["base"];

        if (isset($tpl["links"])) {
            foreach ($tpl["links"] as myKey: $val) {
                $links[myKey] = Text::insert($val, myData, $insertOpts);
            }
        }

        if (!empty($tpl["escapeContext"])) {
            myData["description"] = h(myData["description"]);
        }

        $infoData = compact("code", "context", "trace");
        foreach ($infoData as myKey: myValue) {
            if (empty(myValue) || !isset($tpl[myKey])) {
                continue;
            }
            if (is_array(myValue)) {
                myValue = implode("\n", myValue);
            }
            $info .= Text::insert($tpl[myKey], [myKey: myValue] + myData, $insertOpts);
        }
        $links = implode(" ", $links);

        if (isset($tpl["callback"]) && is_callable($tpl["callback"])) {
            $tpl["callback"](myData, compact("links", "info"));

            return;
        }
        echo Text::insert($tpl["error"], compact("links", "info") + myData, $insertOpts);
    }

    /**
     * Get the type of the given variable. Will return the class name
     * for objects.
     *
     * @param mixed $var The variable to get the type of.
     * @return string The type of variable.
     */
    static string getType($var) {
        myType = getTypeName($var);

        if (myType == "NULL") {
            return "null";
        }

        if (myType == "double") {
            return "float";
        }

        if (myType == "unknown type") {
            return "unknown";
        }

        return myType;
    }

    /**
     * Prints out debug information about given variable.
     *
     * @param mixed $var Variable to show debug information for.
     * @param array myLocation If contains keys "file" and "line" their values will
     *    be used to show location info.
     * @param bool|null $showHtml If set to true, the method prints the debug
     *    data encoded as HTML. If false, plain text formatting will be used.
     *    If null, the format will be chosen based on the configured exportFormatter, or
     *    environment conditions.
     * @return void
     */
    static function printVar($var, array myLocation = [], ?bool $showHtml = null): void
    {
        myLocation += ["file":null, "line":null];
        if (myLocation["file"]) {
            myLocation["file"] = static::trimPath((string)myLocation["file"]);
        }

        $debugger = static::getInstance();
        $restore = null;
        if ($showHtml !== null) {
            $restore = $debugger.getConfig("exportFormatter");
            $debugger.setConfig("exportFormatter", $showHtml ? HtmlFormatter::class : TextFormatter::class);
        }
        myContentss = static::exportVar($var, 25);
        $formatter = $debugger.getExportFormatter();

        if ($restore) {
            $debugger.setConfig("exportFormatter", $restore);
        }
        echo $formatter.formatWrapper(myContentss, myLocation);
    }

    /**
     * Format an exception message to be HTML formatted.
     *
     * Does the following formatting operations:
     *
     * - HTML escape the message.
     * - Convert `bool` into `<code>bool</code>`
     * - Convert newlines into `<br />`
     *
     * @param string myMessage The string message to format.
     * @return Formatted message.
     */
    static function formatHtmlMessage(string myMessage) {
        myMessage = h(myMessage);
        myMessage = preg_replace("/`([^`]+)`/", "<code>$1</code>", myMessage);
        myMessage = nl2br(myMessage);

        return myMessage;
    }

    /**
     * Verifies that the application"s salt and cipher seed value has been changed from the default value.
     *
     * @return void
     */
    static function checkSecurityKeys(): void
    {
        $salt = Security::getSalt();
        if ($salt == "__SALT__" || strlen($salt) < 32) {
            trigger_error(
                "Please change the value of `Security.salt` in `ROOT/config/app_local.php` " .
                "to a random value of at least 32 characters.",
                E_USER_NOTICE
            );
        }
    }
}
