module uim.cake.command;

import uim.cake.console.Arguments;
import uim.cake.console.consoleIo;
import uim.cake.console.consoleOptionParser;
import uim.cake.core.App;
import uim.cake.core.Configure;
import uim.cake.core.Plugin;
import uim.cakelesystem\Filesystem;
import uim.cakeility\Inflector;

/**
 * Language string extractor
 */
class I18nExtractCommand : Command {
    
    static string defaultName() {
        return "i18n extract";
    }

    /**
     * Paths to use when looking for strings
     */
    protected string[] $_paths;

    /**
     * Files from where to extract
     */
    protected string[] $_files;

    // Merge all domain strings into the default.pot file
    protected bool $_merge = false;

    /**
     * Current file being processed
     */
    protected string _file = "";

    /**
     * Contains all content waiting to be written
     *
     * @var array<string, mixed>
     */
    protected _storage = [];

    /**
     * Extracted tokens
     *
     * @var array
     */
    protected _tokens = [];

    /**
     * Extracted strings indexed by domain.
     *
     * @var array<string, mixed>
     */
    protected _translations = [];

    /**
     * Destination path
     */
    protected string _output = "";

    /**
     * An array of directories to exclude.
     *
     * @var array<string>
     */
    protected _exclude = [];

    /**
     * Holds whether this call should extract the UIM Lib messages
     *
     * @var bool
     */
    protected _extractCore = false;

    /**
     * Displays marker error(s) if true
     *
     * @var bool
     */
    protected _markerError = false;

    /**
     * Count number of marker errors found
     *
     * @var int
     */
    protected _countMarkerError = 0;

    /**
     * Method to interact with the user and get path selections.
     *
     * @param uim.cake.consoles.ConsoleIo $io The io instance.
     */
    protected void _getPaths(ConsoleIo $io) {
        /** @psalm-suppress UndefinedConstant */
        $defaultPaths = array_merge(
            [APP],
            App::path("templates"),
            ["D"] // This is required to break the loop below
        );
        $defaultPathIndex = 0;
        while (true) {
            $currentPaths = count(_paths) > 0 ? _paths : ["None"];
            myMessage = sprintf(
                "Current paths: %s\nWhat is the path you would like to extract?\n[Q]uit [D]one",
                implode(", ", $currentPaths)
            );
            $response = $io.ask(myMessage, $defaultPaths[$defaultPathIndex] ?? "D");
            if (strtoupper($response) == "Q") {
                $io.err("Extract Aborted");
                this.abort();

                return;
            }
            if (strtoupper($response) == "D" && count(_paths)) {
                $io.out();

                return;
            }
            if (strtoupper($response) == "D") {
                $io.warning("No directories selected. Please choose a directory.");
            } elseif (is_dir($response)) {
                _paths[] = $response;
                $defaultPathIndex++;
            } else {
                $io.err("The directory path you supplied was not found. Please try again.");
            }
            $io.out();
        }
    }

    /**
     * Execute the command
     *
     * @param uim.cake.consoles.Arguments $args The command arguments.
     * @param uim.cake.consoles.ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    Nullable!int execute(Arguments $args, ConsoleIo $io) {
        myPlugin = "";
        if ($args.getOption("exclude")) {
            _exclude = explode(",", (string)$args.getOption("exclude"));
        }
        if ($args.getOption("files")) {
            _files = explode(",", (string)$args.getOption("files"));
        }
        if ($args.getOption("paths")) {
            _paths = explode(",", (string)$args.getOption("paths"));
        } elseif ($args.getOption("plugin")) {
            myPlugin = Inflector::camelize((string)$args.getOption("plugin"));
            _paths = [Plugin::classPath(myPlugin), Plugin::templatePath(myPlugin)];
        } else {
            _getPaths($io);
        }

        if ($args.hasOption("extract-core")) {
            _extractCore = !(strtolower((string)$args.getOption("extract-core")) == "no");
        } else {
            $response = $io.askChoice(
                "Would you like to extract the messages from the UIM core?",
                ["y", "n"],
                "n"
            );
            _extractCore = strtolower($response) == "y";
        }

        if ($args.hasOption("exclude-plugins") && _isExtractingApp()) {
            _exclude = array_merge(_exclude, App::path("plugins"));
        }

        if (_extractCore) {
            _paths[] = CAKE;
        }

        if ($args.hasOption("output")) {
            _output = (string)$args.getOption("output");
        } elseif ($args.hasOption("plugin")) {
            _output = Plugin::path(myPlugin)
                ~ "resources" ~ DIRECTORY_SEPARATOR
                ~ "locales" ~ DIRECTORY_SEPARATOR;
        } else {
            myMessage = "What is the path you would like to output?\n[Q]uit";
            $localePaths = App::path("locales");
            if (!$localePaths) {
                $localePaths[] = ROOT ~ "resources" ~ DIRECTORY_SEPARATOR ~ "locales";
            }
            while (true) {
                $response = $io.ask(
                    myMessage,
                    $localePaths[0]
                );
                if (strtoupper($response) == "Q") {
                    $io.err("Extract Aborted");

                    return static::CODE_ERROR;
                }
                if (_isPathUsable($response)) {
                    _output = $response . DIRECTORY_SEPARATOR;
                    break;
                }

                $io.err("");
                $io.err(
                    "<error>The directory path you supplied was " ~
                    "not found. Please try again.</error>"
                );
                $io.err("");
            }
        }

        if ($args.hasOption("merge")) {
            _merge = !(strtolower((string)$args.getOption("merge")) == "no");
        } else {
            $io.out();
            $response = $io.askChoice(
                "Would you like to merge all domain strings into the default.pot file?",
                ["y", "n"],
                "n"
            );
            _merge = strtolower($response) == "y";
        }

        _markerError = (bool)$args.getOption("marker-error");

        if (empty(_files)) {
            _searchFiles();
        }

        _output = rtrim(_output, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR;
        if (!_isPathUsable(_output)) {
            $io.err(sprintf("The output directory %s was not found or writable.", _output));

            return static::CODE_ERROR;
        }

        _extract($args, $io);

        return static::CODE_SUCCESS;
    }

    /**
     * Add a translation to the internal translations property
     *
     * Takes care of duplicate translations
     *
     * @param string domain The domain
     * @param string msgid The message string
     * @param array $details Context and plural form if any, file and line references
     */
    protected void _addTranslation(string domain, string msgid, array $details = []) {
        $context = $details["msgctxt"] ?? "";

        if (empty(_translations[$domain][$msgid][$context])) {
            _translations[$domain][$msgid][$context] = [
                "msgid_plural":false,
            ];
        }

        if (isset($details["msgid_plural"])) {
            _translations[$domain][$msgid][$context]["msgid_plural"] = $details["msgid_plural"];
        }

        if (isset($details["file"])) {
            $line = $details["line"] ?? 0;
            _translations[$domain][$msgid][$context]["references"][$details["file"]][] = $line;
        }
    }

    /**
     * Extract text
     *
     * @param uim.cake.consoles.Arguments $args The Arguments instance
     * @param uim.cake.consoles.ConsoleIo $io The io instance
     */
    protected void _extract(Arguments $args, ConsoleIo $io) {
        $io.out();
        $io.out();
        $io.out("Extracting...");
        $io.hr();
        $io.out("Paths:");
        foreach (myPath; _paths) {
            $io.out("   " ~ myPath);
        }
        $io.out("Output Directory: " ~ _output);
        $io.hr();
        _extractTokens($args, $io);
        _buildFiles($args);
        _writeFiles($args, $io);
        _paths = _files = _storage = [];
        _translations = _tokens = [];
        $io.out();
        if (_countMarkerError) {
            $io.err("{_countMarkerError} marker error(s) detected.");
            $io.err(":Use the --marker-error option to display errors.");
        }

        $io.out("Done.");
    }

    /**
     * Gets the option parser instance and configures it.
     *
     * @param uim.cake.consoles.ConsoleOptionParser $parser The parser to configure
     * @return uim.cake.consoles.ConsoleOptionParser
     */
    ConsoleOptionParser buildOptionParser(ConsoleOptionParser $parser) {
        $parser.setDescription(
            "Extract i18n POT files from application source files~ " ~
            "Source files are parsed and string literal format strings " ~
            "provided to the <info>__</info> family of functions are extracted."
        ).addOption("app", [
            "help":"Directory where your application is located.",
        ]).addOption("paths", [
            "help":"Comma separated list of paths that are searched for source files.",
        ]).addOption("merge", [
            "help":"Merge all domain strings into a single default.po file.",
            "default":"no",
            "choices":["yes", "no"],
        ]).addOption("output", [
            "help":"Full path to output directory.",
        ]).addOption("files", [
            "help":"Comma separated list of files to parse.",
        ]).addOption("exclude-plugins", [
            "boolean":true,
            "default":true,
            "help":"Ignores all files in plugins if this command is run inside from the same app directory.",
        ]).addOption("plugin", [
            "help":"Extracts tokens only from the plugin specified and "
                ~ "puts the result in the plugin\"s `locales` directory.",
            "short":"p",
        ]).addOption("exclude", [
            "help":"Comma separated list of directories to exclude." ~
                " Any path containing a path segment with the provided values will be skipped. E.g. test,vendors",
        ]).addOption("overwrite", [
            "boolean":true,
            "default":false,
            "help":"Always overwrite existing .pot files.",
        ]).addOption("extract-core", [
<<<<<<< HEAD
            "help":"Extract messages from the CakePHP core libraries.",
            "choices":["yes", "no"],
!==
            "help": "Extract messages from the UIM core libraries.",
            "choices": ["yes", "no"],
>>>>>>> 7150a867e48cdb2613daa023accf8964a29f88b9
        ]).addOption("no-location", [
            "boolean":true,
            "default":false,
            "help":"Do not write file locations for each extracted message.",
        ]).addOption("marker-error", [
            "boolean":true,
            "default":false,
            "help":"Do not display marker error.",
        ]);

        return $parser;
    }

    /**
     * Extract tokens out of all files to be processed
     *
     * @param uim.cake.consoles.Arguments $args The io instance
     * @param uim.cake.consoles.ConsoleIo $io The io instance
     */
    protected void _extractTokens(Arguments $args, ConsoleIo $io) {
        /** @var uim.cake.Shell\Helper\ProgressHelper $progress */
        $progress = $io.helper("progress");
        $progress.init(["total":count(_files)]);
        $isVerbose = $args.getOption("verbose");

        $functions = [
            "__":["singular"],
            "__n":["singular", "plural"],
            "__d":["domain", "singular"],
            "__dn":["domain", "singular", "plural"],
            "__x":["context", "singular"],
            "__xn":["context", "singular", "plural"],
            "__dx":["domain", "context", "singular"],
            "__dxn":["domain", "context", "singular", "plural"],
        ];
        $pattern = "/(" ~ implode("|", array_keys($functions)) ~ ")\s*\(/";

        foreach (myfile; _files) {
            _file = myfile;
            if ($isVerbose) {
                $io.verbose(sprintf("Processing %s...", myfile));
            }

            $code = file_get_contents(myfile);

            if (preg_match($pattern, $code) == 1) {
                $allTokens = token_get_all($code);

                _tokens = [];
                foreach ($token; $allTokens) {
                    if (!is_array($token) || ($token[0] != T_WHITESPACE && $token[0] != T_INLINE_HTML)) {
                        _tokens[] = $token;
                    }
                }
                unset($allTokens);

                foreach ($functions as $functionName: $map) {
                    _parse($io, $functionName, $map);
                }
            }

            if (!$isVerbose) {
                $progress.increment(1);
                $progress.draw();
            }
        }
    }

    /**
     * Parse tokens
     *
     * @param uim.cake.consoles.ConsoleIo $io The io instance
     * @param string functionName Function name that indicates translatable string (e.g: "__")
     * @param array $map Array containing what variables it will find (e.g: domain, singular, plural)
     */
    protected void _parse(ConsoleIo $io, string functionName, array $map) {
        myCount = 0;
        $tokenCount = count(_tokens);

        while ($tokenCount - myCount > 1) {
            myCountToken = _tokens[myCount];
            $firstParenthesis = _tokens[myCount + 1];
            if (!is_array(myCountToken)) {
                myCount++;
                continue;
            }

            [myType, $string, $line] = myCountToken;
            if ((myType == T_STRING) && ($string == $functionName) && ($firstParenthesis == "(")) {
                $position = myCount;
                $depth = 0;

                while (!$depth) {
                    if (_tokens[$position] == "(") {
                        $depth++;
                    } elseif (_tokens[$position] == ")") {
                        $depth--;
                    }
                    $position++;
                }

                $mapCount = count($map);
                $strings = _getStrings($position, $mapCount);

                if ($mapCount == count($strings)) {
                    $singular = "";
                    $plural = $context = null;
                    $vars = array_combine($map, $strings);
                    extract($vars);
                    $domain = $domain ?? "default";
                    $details = [
                        "file":_file,
                        "line":$line,
                    ];
                    $details["file"] = "." ~ str_replace(ROOT, "", $details["file"]);
                    if ($plural  !is null) {
                        $details["msgid_plural"] = $plural;
                    }
                    if ($context  !is null) {
                        $details["msgctxt"] = $context;
                    }
                    _addTranslation($domain, $singular, $details);
                } else {
                    _markerError($io, _file, $line, $functionName, myCount);
                }
            }
            myCount++;
        }
    }

    /**
     * Build the translate template file contents out of obtained strings
     *
     * @param uim.cake.consoles.Arguments $args Console arguments
     */
    protected void _buildFiles(Arguments $args) {
        myPaths = _paths;
        /** @psalm-suppress UndefinedConstant */
        myPaths[] = realpath(APP) . DIRECTORY_SEPARATOR;

        usort(myPaths, function (string a, string b) {
            return strlen($a) - strlen($b);
        });

        foreach ($domain: $translations; _translations) {
            foreach ($msgid: $contexts; $translations) {
                foreach ($context, $details; $contexts) {
                    $plural = $details["msgid_plural"];
                    myfiles = $details["references"];
                    $header = "";

                    if (!$args.getOption("no-location")) {
                        $occurrences = [];
                        foreach (myfile, $lines; myfiles) {
                            $lines = array_unique($lines);
                            foreach ($lines as $line) {
                                $occurrences[] = myfile ~ ":" ~ $line;
                            }
                        }
                        $occurrences = implode("\n#: ", $occurrences);

                        $header = "#: "
                            . str_replace(DIRECTORY_SEPARATOR, "/", $occurrences)
                            ~ "\n";
                    }

                    $sentence = "";
                    if ($context != "") {
                        $sentence .= "msgctxt \"{$context}\"\n";
                    }
                    if ($plural == false) {
                        $sentence .= "msgid \"{$msgid}\"\n";
                        $sentence .= "msgstr \"\"\n\n";
                    } else {
                        $sentence .= "msgid \"{$msgid}\"\n";
                        $sentence .= "msgid_plural \"{$plural}\"\n";
                        $sentence .= "msgstr[0] \"\"\n";
                        $sentence .= "msgstr[1] \"\"\n\n";
                    }

                    if ($domain != "default" && _merge) {
                        _store("default", $header, $sentence);
                    } else {
                        _store($domain, $header, $sentence);
                    }
                }
            }
        }
    }

    /**
     * Prepare a file to be stored
     *
     * @param string domain The domain
     * @param string header The header content.
     * @param string sentence The sentence to store.
     */
    protected void _store(string domain, string header, string sentence) {
        _storage[$domain] = _storage[$domain] ?? [];

        if (!isset(_storage[$domain][$sentence])) {
            _storage[$domain][$sentence] = $header;
        } else {
            _storage[$domain][$sentence] .= $header;
        }
    }

    /**
     * Write the files that need to be stored
     *
     * @param uim.cake.consoles.Arguments $args The command arguments.
     * @param uim.cake.consoles.ConsoleIo $io The console io
     */
    protected void _writeFiles(Arguments $args, ConsoleIo $io) {
        $io.out();
        $overwriteAll = false;
        if ($args.getOption("overwrite")) {
            $overwriteAll = true;
        }
        foreach ($domain, $sentences; _storage) {
            $output = _writeHeader($domain);
            $headerLength = strlen($output);
            foreach ($sentence, $header; $sentences) {
                $output .= $header . $sentence;
            }

            // Remove vendor prefix if present.
            $slashPosition = indexOf($domain, "/");
            if ($slashPosition != false) {
                $domain = substr($domain, $slashPosition + 1);
            }

            myfilename = str_replace("/", "_", $domain) ~ ".pot";
            $outputPath = _output . myfilename;

            if (this.checkUnchanged($outputPath, $headerLength, $output) == true) {
                $io.out(myfilename ~ " is unchanged. Skipping.");
                continue;
            }

            $response = "";
            while ($overwriteAll == false && file_exists($outputPath) && strtoupper($response) != "Y") {
                $io.out();
                $response = $io.askChoice(
                    sprintf("Error: %s already exists in this location. Overwrite? [Y]es, [N]o, [A]ll", myfilename),
                    ["y", "n", "a"],
                    "y"
                );
                if (strtoupper($response) == "N") {
                    $response = "";
                    while (!$response) {
                        $response = $io.ask("What would you like to name this file?", "new_" ~ myfilename);
                        myfilename = $response;
                    }
                } elseif (strtoupper($response) == "A") {
                    $overwriteAll = true;
                }
            }
            $fs = new Filesystem();
            $fs.dumpFile(_output . myfilename, $output);
        }
    }

    /**
     * Build the translation template header
     *
     * @param $domain Domain
     * @return Translation template header
     */
    protected string _writeHeader(string domain) {
        $projectIdVersion = $domain == "cake" ? "UIM " ~ Configure::version() : "PROJECT VERSION";

        $output = "# LANGUAGE translation of UIM Application\n";
        $output .= "# Copyright YEAR NAME <EMAIL@ADDRESS>\n";
        $output .= "#\n";
        $output .= "#, fuzzy\n";
        $output .= "msgid \"\"\n";
        $output .= "msgstr \"\"\n";
        $output .= ""Project-Id-Version: " ~ $projectIdVersion ~ "\\n\"\n";
        $output .= ""POT-Creation-Date: " ~ date("Y-m-d H:iO") ~ "\\n\"\n";
        $output .= "\"PO-Revision-Date: YYYY-mm-DD HH:MM+ZZZZ\\n\"\n";
        $output .= "\"Last-Translator: NAME <EMAIL@ADDRESS>\\n\"\n";
        $output .= "\"Language-Team: LANGUAGE <EMAIL@ADDRESS>\\n\"\n";
        $output .= "\"MIME-Version: 1.0\\n\"\n";
        $output .= "\"Content-Type: text/plain; charset=utf-8\\n\"\n";
        $output .= "\"Content-Transfer-Encoding: 8bit\\n\"\n";
        $output .= "\"Plural-Forms: nplurals=INTEGER; plural=EXPRESSION;\\n\"\n\n";

        return $output;
    }

    /**
     * Check whether the old and new output are the same, thus unchanged
     *
     * Compares the sha1 hashes of the old and new file without header.
     *
     * @param string oldFile The existing file.
     * @param int $headerLength The length of the file header in bytes.
     * @param string newFileContent The content of the new file.
     * @return bool Whether the old and new file are unchanged.
     */
    protected bool checkUnchanged(string oldFile, int $headerLength, string newFileContent) {
        if (!file_exists($oldFile)) {
            return false;
        }
        $oldFileContent = file_get_contents($oldFile);

        $oldChecksum = sha1((string)substr($oldFileContent, $headerLength));
        $newChecksum = sha1((string)substr($newFileContent, $headerLength));

        return $oldChecksum == $newChecksum;
    }

    /**
     * Get the strings from the position forward
     *
     * @param int $position Actual position on tokens array
     * @param int myTarget Number of strings to extract
     * @return array Strings extracted
     */
    array auto _getStrings(int &$position, int myTarget) {
        $strings = [];
        myCount = 0;
        while (
            myCount < myTarget
            && (_tokens[$position] == ","
                || _tokens[$position][0] == T_CONSTANT_ENCAPSED_STRING
                || _tokens[$position][0] == T_LNUMBER
            )
        ) {
            myCount = count($strings);
            if (_tokens[$position][0] == T_CONSTANT_ENCAPSED_STRING && _tokens[$position + 1] == ".") {
                $string = "";
                while (
                    _tokens[$position][0] == T_CONSTANT_ENCAPSED_STRING
                    || _tokens[$position] == "."
                ) {
                    if (_tokens[$position][0] == T_CONSTANT_ENCAPSED_STRING) {
                        $string .= _formatString(_tokens[$position][1]);
                    }
                    $position++;
                }
                $strings[] = $string;
            } elseif (_tokens[$position][0] == T_CONSTANT_ENCAPSED_STRING) {
                $strings[] = _formatString(_tokens[$position][1]);
            } elseif (_tokens[$position][0] == T_LNUMBER) {
                $strings[] = _tokens[$position][1];
            }
            $position++;
        }

        return $strings;
    }

    /**
     * Format a string to be added as a translatable string
     *
     * @param string string String to format
     * @return  Formatted string
     */
    protected string _formatString(string string) {
        $quote = substr($string, 0, 1);
        $string = substr($string, 1, -1);
        if ($quote == """) {
            $string = stripcslashes($string);
        } else {
            $string = strtr($string, ["\\"":""", "\\\\":"\\"]);
        }
        $string = str_replace("\r\n", "\n", $string);

        return addcslashes($string, "\0..\37\\\"");
    }

    /**
     * Indicate an invalid marker on a processed file
     *
     * @param uim.cake.consoles.ConsoleIo $io The io instance.
     * @param string myfile File where invalid marker resides
     * @param int $line Line number
     * @param string marker Marker found
     * @param int myCount Count
     */
    protected void _markerError($io, string myfile, int $line, string marker, int myCount) {
        if (indexOf(_file, CAKE_CORE_INCLUDE_PATH) == false) {
            _countMarkerError++;
        }

        if (!_markerError) {
            return;
        }

        $io.err(sprintf("Invalid marker content in %s:%s\n* %s(", myfile, $line, $marker));
        myCount += 2;
        $tokenCount = count(_tokens);
        $parenthesis = 1;

        while (($tokenCount - myCount > 0) && $parenthesis) {
            if (is_array(_tokens[myCount])) {
                $io.err(_tokens[myCount][1], 0);
            } else {
                $io.err(_tokens[myCount], 0);
                if (_tokens[myCount] == "(") {
                    $parenthesis++;
                }

                if (_tokens[myCount] == ")") {
                    $parenthesis--;
                }
            }
            myCount++;
        }
        $io.err("\n");
    }

    /**
     * Search files that may contain translatable strings
     */
    protected void _searchFiles() {
        $pattern = false;
        if (!empty(_exclude)) {
            $exclude = [];
            foreach ($e; _exclude) 
                if (DIRECTORY_SEPARATOR != "\\" && $e[0] != DIRECTORY_SEPARATOR) {
                    $e = DIRECTORY_SEPARATOR . $e;
                }
                $exclude[] = preg_quote($e, "/");
            }
            $pattern = "/" ~ implode("|", $exclude) ~ "/";
        }

        foreach (_paths as myPath) {
            myPath = realpath(myPath) . DIRECTORY_SEPARATOR;
            $fs = new Filesystem();
            myfiles = $fs.findRecursive(myPath, "/\.php$/");
            myfiles = array_keys(iterator_to_array(myfiles));
            sort(myfiles);
            if (!empty($pattern)) {
                myfiles = preg_grep($pattern, myfiles, PREG_GREP_INVERT);
                myfiles = array_values(myfiles);
            }
            _files = array_merge(_files, myfiles);
        }
        _files = array_unique(_files);
    }

    /**
     * Returns whether this execution is meant to extract string only from directories in folder represented by the
     * APP constant, i.e. this task is extracting strings from same application.
     */
    protected bool _isExtractingApp() {
        /** @psalm-suppress UndefinedConstant */
        return _paths == [APP];
    }

    /**
     * Checks whether a given path is usable for writing.
     *
     * @param string myPath Path to folder
     * @return bool true if it exists and is writable, false otherwise
     */
    protected bool _isPathUsable(myPath) {
        if (!is_dir(myPath)) {
            mkdir(myPath, 0770, true);
        }

        return is_dir(myPath) && is_writable(myPath);
    }
}
