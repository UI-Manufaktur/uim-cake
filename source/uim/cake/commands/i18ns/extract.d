module uim.cake.command;

import uim.cake.console.Arguments;
import uim.cake.console.consoleIo;
import uim.cake.console.consoleOptionParser;
import uim.cake.core.App;
import uim.cake.core.Configure;
import uim.cake.core.Plugin;
import uim.cake.Filesystem\Filesystem;
import uim.cake.Utility\Inflector;

/**
 * Language string extractor
 */
class I18nExtractCommand : Command {

    static string defaultName() {
        return 'i18n extract';
    }

    /**
     * Paths to use when looking for strings
     *
     * @var array<string>
     */
    protected $_paths = [];

    /**
     * Files from where to extract
     *
     * @var array<string>
     */
    protected $_files = [];

    /**
     * Merge all domain strings into the default.pot file
     *
     * @var bool
     */
    protected $_merge = false;

    /**
     * Current file being processed
     *
     * @var string
     */
    protected $_file = '';

    /**
     * Contains all content waiting to be written
     *
     * @var array<string, mixed>
     */
    protected $_storage = [];

    /**
     * Extracted tokens
     *
     * @var array
     */
    protected $_tokens = [];

    /**
     * Extracted strings indexed by domain.
     *
     * @var array<string, mixed>
     */
    protected $_translations = [];

    /**
     * Destination path
     *
     * @var string
     */
    protected $_output = '';

    /**
     * An array of directories to exclude.
     *
     * @var array<string>
     */
    protected $_exclude = [];

    /**
     * Holds whether this call should extract the CakePHP Lib messages
     *
     * @var bool
     */
    protected $_extractCore = false;

    /**
     * Displays marker error(s) if true
     *
     * @var bool
     */
    protected $_markerError = false;

    /**
     * Count number of marker errors found
     *
     * @var int
     */
    protected $_countMarkerError = 0;

    /**
     * Method to interact with the user and get path selections.
     *
     * @param \Cake\Console\ConsoleIo $io The io instance.
     * @return void
     */
    protected void _getPaths(ConsoleIo $io) {
        /** @psalm-suppress UndefinedConstant */
        $defaultPaths = array_merge(
            [APP],
            App::path('templates'),
            ['D'] // This is required to break the loop below
        );
        $defaultPathIndex = 0;
        while (true) {
            $currentPaths = count(this._paths) > 0 ? this._paths : ['None'];
            myMessage = sprintf(
                "Current paths: %s\nWhat is the path you would like to extract?\n[Q]uit [D]one",
                implode(', ', $currentPaths)
            );
            $response = $io.ask(myMessage, $defaultPaths[$defaultPathIndex] ?? 'D');
            if (strtoupper($response) === 'Q') {
                $io.err('Extract Aborted');
                this.abort();

                return;
            }
            if (strtoupper($response) === 'D' && count(this._paths)) {
                $io.out();

                return;
            }
            if (strtoupper($response) === 'D') {
                $io.warning('No directories selected. Please choose a directory.');
            } elseif (is_dir($response)) {
                this._paths[] = $response;
                $defaultPathIndex++;
            } else {
                $io.err('The directory path you supplied was not found. Please try again.');
            }
            $io.out();
        }
    }

    /**
     * Execute the command
     *
     * @param \Cake\Console\Arguments $args The command arguments.
     * @param \Cake\Console\ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    auto execute(Arguments $args, ConsoleIo $io): ?int
    {
        myPlugin = '';
        if ($args.getOption('exclude')) {
            this._exclude = explode(',', (string)$args.getOption('exclude'));
        }
        if ($args.getOption('files')) {
            this._files = explode(',', (string)$args.getOption('files'));
        }
        if ($args.getOption('paths')) {
            this._paths = explode(',', (string)$args.getOption('paths'));
        } elseif ($args.getOption('plugin')) {
            myPlugin = Inflector::camelize((string)$args.getOption('plugin'));
            this._paths = [Plugin::classPath(myPlugin), Plugin::templatePath(myPlugin)];
        } else {
            this._getPaths($io);
        }

        if ($args.hasOption('extract-core')) {
            this._extractCore = !(strtolower((string)$args.getOption('extract-core')) === 'no');
        } else {
            $response = $io.askChoice(
                'Would you like to extract the messages from the CakePHP core?',
                ['y', 'n'],
                'n'
            );
            this._extractCore = strtolower($response) === 'y';
        }

        if ($args.hasOption('exclude-plugins') && this._isExtractingApp()) {
            this._exclude = array_merge(this._exclude, App::path('plugins'));
        }

        if (this._extractCore) {
            this._paths[] = CAKE;
        }

        if ($args.hasOption('output')) {
            this._output = (string)$args.getOption('output');
        } elseif ($args.hasOption('plugin')) {
            this._output = Plugin::path(myPlugin)
                . 'resources' . DIRECTORY_SEPARATOR
                . 'locales' . DIRECTORY_SEPARATOR;
        } else {
            myMessage = "What is the path you would like to output?\n[Q]uit";
            $localePaths = App::path('locales');
            if (!$localePaths) {
                $localePaths[] = ROOT . 'resources' . DIRECTORY_SEPARATOR . 'locales';
            }
            while (true) {
                $response = $io.ask(
                    myMessage,
                    $localePaths[0]
                );
                if (strtoupper($response) === 'Q') {
                    $io.err('Extract Aborted');

                    return static::CODE_ERROR;
                }
                if (this._isPathUsable($response)) {
                    this._output = $response . DIRECTORY_SEPARATOR;
                    break;
                }

                $io.err('');
                $io.err(
                    '<error>The directory path you supplied was ' .
                    'not found. Please try again.</error>'
                );
                $io.err('');
            }
        }

        if ($args.hasOption('merge')) {
            this._merge = !(strtolower((string)$args.getOption('merge')) === 'no');
        } else {
            $io.out();
            $response = $io.askChoice(
                'Would you like to merge all domain strings into the default.pot file?',
                ['y', 'n'],
                'n'
            );
            this._merge = strtolower($response) === 'y';
        }

        this._markerError = (bool)$args.getOption('marker-error');

        if (empty(this._files)) {
            this._searchFiles();
        }

        this._output = rtrim(this._output, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR;
        if (!this._isPathUsable(this._output)) {
            $io.err(sprintf('The output directory %s was not found or writable.', this._output));

            return static::CODE_ERROR;
        }

        this._extract($args, $io);

        return static::CODE_SUCCESS;
    }

    /**
     * Add a translation to the internal translations property
     *
     * Takes care of duplicate translations
     *
     * @param string $domain The domain
     * @param string $msgid The message string
     * @param array $details Context and plural form if any, file and line references
     * @return void
     */
    protected void _addTranslation(string $domain, string $msgid, array $details = []) {
        $context = $details['msgctxt'] ?? '';

        if (empty(this._translations[$domain][$msgid][$context])) {
            this._translations[$domain][$msgid][$context] = [
                'msgid_plural' => false,
            ];
        }

        if (isset($details['msgid_plural'])) {
            this._translations[$domain][$msgid][$context]['msgid_plural'] = $details['msgid_plural'];
        }

        if (isset($details['file'])) {
            $line = $details['line'] ?? 0;
            this._translations[$domain][$msgid][$context]['references'][$details['file']][] = $line;
        }
    }

    /**
     * Extract text
     *
     * @param \Cake\Console\Arguments $args The Arguments instance
     * @param \Cake\Console\ConsoleIo $io The io instance
     * @return void
     */
    protected void _extract(Arguments $args, ConsoleIo $io) {
        $io.out();
        $io.out();
        $io.out('Extracting...');
        $io.hr();
        $io.out('Paths:');
        foreach (this._paths as myPath) {
            $io.out('   ' . myPath);
        }
        $io.out('Output Directory: ' . this._output);
        $io.hr();
        this._extractTokens($args, $io);
        this._buildFiles($args);
        this._writeFiles($args, $io);
        this._paths = this._files = this._storage = [];
        this._translations = this._tokens = [];
        $io.out();
        if (this._countMarkerError) {
            $io.err("{this._countMarkerError} marker error(s) detected.");
            $io.err(' => Use the --marker-error option to display errors.');
        }

        $io.out('Done.');
    }

    /**
     * Gets the option parser instance and configures it.
     *
     * @param \Cake\Console\ConsoleOptionParser $parser The parser to configure
     * @return \Cake\Console\ConsoleOptionParser
     */
    function buildOptionParser(ConsoleOptionParser $parser): ConsoleOptionParser
    {
        $parser.setDescription(
            'Extract i18n POT files from application source files. ' .
            'Source files are parsed and string literal format strings ' .
            'provided to the <info>__</info> family of functions are extracted.'
        ).addOption('app', [
            'help' => 'Directory where your application is located.',
        ]).addOption('paths', [
            'help' => 'Comma separated list of paths that are searched for source files.',
        ]).addOption('merge', [
            'help' => 'Merge all domain strings into a single default.po file.',
            'default' => 'no',
            'choices' => ['yes', 'no'],
        ]).addOption('output', [
            'help' => 'Full path to output directory.',
        ]).addOption('files', [
            'help' => 'Comma separated list of files to parse.',
        ]).addOption('exclude-plugins', [
            'boolean' => true,
            'default' => true,
            'help' => 'Ignores all files in plugins if this command is run inside from the same app directory.',
        ]).addOption('plugin', [
            'help' => 'Extracts tokens only from the plugin specified and '
                . 'puts the result in the plugin\'s `locales` directory.',
            'short' => 'p',
        ]).addOption('exclude', [
            'help' => 'Comma separated list of directories to exclude.' .
                ' Any path containing a path segment with the provided values will be skipped. E.g. test,vendors',
        ]).addOption('overwrite', [
            'boolean' => true,
            'default' => false,
            'help' => 'Always overwrite existing .pot files.',
        ]).addOption('extract-core', [
            'help' => 'Extract messages from the CakePHP core libraries.',
            'choices' => ['yes', 'no'],
        ]).addOption('no-location', [
            'boolean' => true,
            'default' => false,
            'help' => 'Do not write file locations for each extracted message.',
        ]).addOption('marker-error', [
            'boolean' => true,
            'default' => false,
            'help' => 'Do not display marker error.',
        ]);

        return $parser;
    }

    /**
     * Extract tokens out of all files to be processed
     *
     * @param \Cake\Console\Arguments $args The io instance
     * @param \Cake\Console\ConsoleIo $io The io instance
     * @return void
     */
    protected void _extractTokens(Arguments $args, ConsoleIo $io) {
        /** @var \Cake\Shell\Helper\ProgressHelper $progress */
        $progress = $io.helper('progress');
        $progress.init(['total' => count(this._files)]);
        $isVerbose = $args.getOption('verbose');

        $functions = [
            '__' => ['singular'],
            '__n' => ['singular', 'plural'],
            '__d' => ['domain', 'singular'],
            '__dn' => ['domain', 'singular', 'plural'],
            '__x' => ['context', 'singular'],
            '__xn' => ['context', 'singular', 'plural'],
            '__dx' => ['domain', 'context', 'singular'],
            '__dxn' => ['domain', 'context', 'singular', 'plural'],
        ];
        $pattern = '/(' . implode('|', array_keys($functions)) . ')\s*\(/';

        foreach (this._files as $file) {
            this._file = $file;
            if ($isVerbose) {
                $io.verbose(sprintf('Processing %s...', $file));
            }

            $code = file_get_contents($file);

            if (preg_match($pattern, $code) === 1) {
                $allTokens = token_get_all($code);

                this._tokens = [];
                foreach ($allTokens as $token) {
                    if (!is_array($token) || ($token[0] !== T_WHITESPACE && $token[0] !== T_INLINE_HTML)) {
                        this._tokens[] = $token;
                    }
                }
                unset($allTokens);

                foreach ($functions as $functionName => $map) {
                    this._parse($io, $functionName, $map);
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
     * @param \Cake\Console\ConsoleIo $io The io instance
     * @param string $functionName Function name that indicates translatable string (e.g: '__')
     * @param array $map Array containing what variables it will find (e.g: domain, singular, plural)
     * @return void
     */
    protected void _parse(ConsoleIo $io, string $functionName, array $map) {
        myCount = 0;
        $tokenCount = count(this._tokens);

        while ($tokenCount - myCount > 1) {
            myCountToken = this._tokens[myCount];
            $firstParenthesis = this._tokens[myCount + 1];
            if (!is_array(myCountToken)) {
                myCount++;
                continue;
            }

            [myType, $string, $line] = myCountToken;
            if ((myType === T_STRING) && ($string === $functionName) && ($firstParenthesis === '(')) {
                $position = myCount;
                $depth = 0;

                while (!$depth) {
                    if (this._tokens[$position] === '(') {
                        $depth++;
                    } elseif (this._tokens[$position] === ')') {
                        $depth--;
                    }
                    $position++;
                }

                $mapCount = count($map);
                $strings = this._getStrings($position, $mapCount);

                if ($mapCount === count($strings)) {
                    $singular = '';
                    $plural = $context = null;
                    $vars = array_combine($map, $strings);
                    extract($vars);
                    $domain = $domain ?? 'default';
                    $details = [
                        'file' => this._file,
                        'line' => $line,
                    ];
                    $details['file'] = '.' . str_replace(ROOT, '', $details['file']);
                    if ($plural !== null) {
                        $details['msgid_plural'] = $plural;
                    }
                    if ($context !== null) {
                        $details['msgctxt'] = $context;
                    }
                    this._addTranslation($domain, $singular, $details);
                } else {
                    this._markerError($io, this._file, $line, $functionName, myCount);
                }
            }
            myCount++;
        }
    }

    /**
     * Build the translate template file contents out of obtained strings
     *
     * @param \Cake\Console\Arguments $args Console arguments
     * @return void
     */
    protected void _buildFiles(Arguments $args) {
        myPaths = this._paths;
        /** @psalm-suppress UndefinedConstant */
        myPaths[] = realpath(APP) . DIRECTORY_SEPARATOR;

        usort(myPaths, function (string $a, string $b) {
            return strlen($a) - strlen($b);
        });

        foreach (this._translations as $domain => $translations) {
            foreach ($translations as $msgid => $contexts) {
                foreach ($contexts as $context => $details) {
                    $plural = $details['msgid_plural'];
                    $files = $details['references'];
                    $header = '';

                    if (!$args.getOption('no-location')) {
                        $occurrences = [];
                        foreach ($files as $file => $lines) {
                            $lines = array_unique($lines);
                            foreach ($lines as $line) {
                                $occurrences[] = $file . ':' . $line;
                            }
                        }
                        $occurrences = implode("\n#: ", $occurrences);

                        $header = '#: '
                            . str_replace(DIRECTORY_SEPARATOR, '/', $occurrences)
                            . "\n";
                    }

                    $sentence = '';
                    if ($context !== '') {
                        $sentence .= "msgctxt \"{$context}\"\n";
                    }
                    if ($plural === false) {
                        $sentence .= "msgid \"{$msgid}\"\n";
                        $sentence .= "msgstr \"\"\n\n";
                    } else {
                        $sentence .= "msgid \"{$msgid}\"\n";
                        $sentence .= "msgid_plural \"{$plural}\"\n";
                        $sentence .= "msgstr[0] \"\"\n";
                        $sentence .= "msgstr[1] \"\"\n\n";
                    }

                    if ($domain !== 'default' && this._merge) {
                        this._store('default', $header, $sentence);
                    } else {
                        this._store($domain, $header, $sentence);
                    }
                }
            }
        }
    }

    /**
     * Prepare a file to be stored
     *
     * @param string $domain The domain
     * @param string $header The header content.
     * @param string $sentence The sentence to store.
     * @return void
     */
    protected void _store(string $domain, string $header, string $sentence) {
        this._storage[$domain] = this._storage[$domain] ?? [];

        if (!isset(this._storage[$domain][$sentence])) {
            this._storage[$domain][$sentence] = $header;
        } else {
            this._storage[$domain][$sentence] .= $header;
        }
    }

    /**
     * Write the files that need to be stored
     *
     * @param \Cake\Console\Arguments $args The command arguments.
     * @param \Cake\Console\ConsoleIo $io The console io
     * @return void
     */
    protected void _writeFiles(Arguments $args, ConsoleIo $io) {
        $io.out();
        $overwriteAll = false;
        if ($args.getOption('overwrite')) {
            $overwriteAll = true;
        }
        foreach (this._storage as $domain => $sentences) {
            $output = this._writeHeader($domain);
            $headerLength = strlen($output);
            foreach ($sentences as $sentence => $header) {
                $output .= $header . $sentence;
            }

            // Remove vendor prefix if present.
            $slashPosition = strpos($domain, '/');
            if ($slashPosition !== false) {
                $domain = substr($domain, $slashPosition + 1);
            }

            $filename = str_replace('/', '_', $domain) . '.pot';
            $outputPath = this._output . $filename;

            if (this.checkUnchanged($outputPath, $headerLength, $output) === true) {
                $io.out($filename . ' is unchanged. Skipping.');
                continue;
            }

            $response = '';
            while ($overwriteAll === false && file_exists($outputPath) && strtoupper($response) !== 'Y') {
                $io.out();
                $response = $io.askChoice(
                    sprintf('Error: %s already exists in this location. Overwrite? [Y]es, [N]o, [A]ll', $filename),
                    ['y', 'n', 'a'],
                    'y'
                );
                if (strtoupper($response) === 'N') {
                    $response = '';
                    while (!$response) {
                        $response = $io.ask('What would you like to name this file?', 'new_' . $filename);
                        $filename = $response;
                    }
                } elseif (strtoupper($response) === 'A') {
                    $overwriteAll = true;
                }
            }
            $fs = new Filesystem();
            $fs.dumpFile(this._output . $filename, $output);
        }
    }

    /**
     * Build the translation template header
     *
     * @param string $domain Domain
     * @return string Translation template header
     */
    protected string _writeHeader(string $domain) {
        $projectIdVersion = $domain === 'cake' ? 'CakePHP ' . Configure::version() : 'PROJECT VERSION';

        $output = "# LANGUAGE translation of CakePHP Application\n";
        $output .= "# Copyright YEAR NAME <EMAIL@ADDRESS>\n";
        $output .= "#\n";
        $output .= "#, fuzzy\n";
        $output .= "msgid \"\"\n";
        $output .= "msgstr \"\"\n";
        $output .= '"Project-Id-Version: ' . $projectIdVersion . "\\n\"\n";
        $output .= '"POT-Creation-Date: ' . date('Y-m-d H:iO') . "\\n\"\n";
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
     * @param string $oldFile The existing file.
     * @param int $headerLength The length of the file header in bytes.
     * @param string $newFileContent The content of the new file.
     * @return bool Whether the old and new file are unchanged.
     */
    protected bool checkUnchanged(string $oldFile, int $headerLength, string $newFileContent) {
        if (!file_exists($oldFile)) {
            return false;
        }
        $oldFileContent = file_get_contents($oldFile);

        $oldChecksum = sha1((string)substr($oldFileContent, $headerLength));
        $newChecksum = sha1((string)substr($newFileContent, $headerLength));

        return $oldChecksum === $newChecksum;
    }

    /**
     * Get the strings from the position forward
     *
     * @param int $position Actual position on tokens array
     * @param int myTarget Number of strings to extract
     * @return array Strings extracted
     */
    protected auto _getStrings(int &$position, int myTarget): array
    {
        $strings = [];
        myCount = 0;
        while (
            myCount < myTarget
            && (this._tokens[$position] === ','
                || this._tokens[$position][0] === T_CONSTANT_ENCAPSED_STRING
                || this._tokens[$position][0] === T_LNUMBER
            )
        ) {
            myCount = count($strings);
            if (this._tokens[$position][0] === T_CONSTANT_ENCAPSED_STRING && this._tokens[$position + 1] === '.') {
                $string = '';
                while (
                    this._tokens[$position][0] === T_CONSTANT_ENCAPSED_STRING
                    || this._tokens[$position] === '.'
                ) {
                    if (this._tokens[$position][0] === T_CONSTANT_ENCAPSED_STRING) {
                        $string .= this._formatString(this._tokens[$position][1]);
                    }
                    $position++;
                }
                $strings[] = $string;
            } elseif (this._tokens[$position][0] === T_CONSTANT_ENCAPSED_STRING) {
                $strings[] = this._formatString(this._tokens[$position][1]);
            } elseif (this._tokens[$position][0] === T_LNUMBER) {
                $strings[] = this._tokens[$position][1];
            }
            $position++;
        }

        return $strings;
    }

    /**
     * Format a string to be added as a translatable string
     *
     * @param string $string String to format
     * @return string Formatted string
     */
    protected string _formatString(string $string) {
        $quote = substr($string, 0, 1);
        $string = substr($string, 1, -1);
        if ($quote === '"') {
            $string = stripcslashes($string);
        } else {
            $string = strtr($string, ["\\'" => "'", '\\\\' => '\\']);
        }
        $string = str_replace("\r\n", "\n", $string);

        return addcslashes($string, "\0..\37\\\"");
    }

    /**
     * Indicate an invalid marker on a processed file
     *
     * @param \Cake\Console\ConsoleIo $io The io instance.
     * @param string $file File where invalid marker resides
     * @param int $line Line number
     * @param string $marker Marker found
     * @param int myCount Count
     * @return void
     */
    protected void _markerError($io, string $file, int $line, string $marker, int myCount) {
        if (strpos(this._file, CAKE_CORE_INCLUDE_PATH) === false) {
            this._countMarkerError++;
        }

        if (!this._markerError) {
            return;
        }

        $io.err(sprintf("Invalid marker content in %s:%s\n* %s(", $file, $line, $marker));
        myCount += 2;
        $tokenCount = count(this._tokens);
        $parenthesis = 1;

        while (($tokenCount - myCount > 0) && $parenthesis) {
            if (is_array(this._tokens[myCount])) {
                $io.err(this._tokens[myCount][1], 0);
            } else {
                $io.err(this._tokens[myCount], 0);
                if (this._tokens[myCount] === '(') {
                    $parenthesis++;
                }

                if (this._tokens[myCount] === ')') {
                    $parenthesis--;
                }
            }
            myCount++;
        }
        $io.err("\n");
    }

    /**
     * Search files that may contain translatable strings
     *
     * @return void
     */
    protected void _searchFiles() {
        $pattern = false;
        if (!empty(this._exclude)) {
            $exclude = [];
            foreach (this._exclude as $e) {
                if (DIRECTORY_SEPARATOR !== '\\' && $e[0] !== DIRECTORY_SEPARATOR) {
                    $e = DIRECTORY_SEPARATOR . $e;
                }
                $exclude[] = preg_quote($e, '/');
            }
            $pattern = '/' . implode('|', $exclude) . '/';
        }

        foreach (this._paths as myPath) {
            myPath = realpath(myPath) . DIRECTORY_SEPARATOR;
            $fs = new Filesystem();
            $files = $fs.findRecursive(myPath, '/\.php$/');
            $files = array_keys(iterator_to_array($files));
            sort($files);
            if (!empty($pattern)) {
                $files = preg_grep($pattern, $files, PREG_GREP_INVERT);
                $files = array_values($files);
            }
            this._files = array_merge(this._files, $files);
        }
        this._files = array_unique(this._files);
    }

    /**
     * Returns whether this execution is meant to extract string only from directories in folder represented by the
     * APP constant, i.e. this task is extracting strings from same application.
     *
     * @return bool
     */
    protected bool _isExtractingApp() {
        /** @psalm-suppress UndefinedConstant */
        return this._paths === [APP];
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
