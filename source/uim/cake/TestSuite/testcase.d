

 * @since         1.2.0
  */module uim.cake.TestSuite;

import uim.cake.core.App;
import uim.cake.core.Configure;
import uim.cake.core.Plugin;
import uim.datasources.ConnectionManager;
import uim.cake.events.EventManager;
import uim.cake.http.BaseApplication;
import uim.cake.orm.Entity;
import uim.cake.orm.exceptions.MissingTableClassException;
import uim.cake.orm.locators.LocatorAwareTrait;
import uim.cake.routings.Router;
import uim.cake.TestSuite\Constraint\EventFired;
import uim.cake.TestSuite\Constraint\EventFiredWith;
import uim.cake.TestSuite\Fixture\FixtureStrategyInterface;
import uim.cake.TestSuite\Fixture\TruncateStrategy;
import uim.cake.utilities.Inflector;
use LogicException;
use PHPUnit\Framework\Constraint\DirectoryExists;
use PHPUnit\Framework\Constraint\FileExists;
use PHPUnit\Framework\Constraint\LogicalNot;
use PHPUnit\Framework\Constraint\RegularExpression;
use PHPUnit\Framework\TestCase as BaseTestCase;
use ReflectionClass;
use ReflectionException;
use RuntimeException;

/**
 * Cake TestCase class
 */
abstract class TestCase : BaseTestCase
{
    use LocatorAwareTrait;

    /**
     * The class responsible for managing the creation, loading and removing of fixtures
     *
     * @var uim.cake.TestSuite\Fixture\FixtureManager|null
     */
    static $fixtureManager;

    /**
     * Fixtures used by this test case.
     *
     * @var array<string>
     */
    protected $fixtures = null;

    /**
     * By default, all fixtures attached to this class will be truncated and reloaded after each test.
     * Set this to false to handle manually
     *
     * @var bool
     * @deprecated 4.3.0 autoFixtures is only used by deprecated fixture features.
     *   This property will be removed in 5.0
     */
    $autoFixtures = true;

    /**
     * Control table create/drops on each test method.
     *
     * If true, tables will still be dropped at the
     * end of each test runner execution.
     *
     * @var bool
     * @deprecated 4.3.0 dropTables is only used by deprecated fixture features.
     *   This property will be removed in 5.0
     */
    $dropTables = false;

    /**
     * @var uim.cake.TestSuite\Fixture\FixtureStrategyInterface|null
     */
    protected $fixtureStrategy = null;

    /**
     * Configure values to restore at end of test.
     *
     * @var array
     */
    protected _configure = null;

    /**
     * Asserts that a string matches a given regular expression.
     *
     * @param string $pattern Regex pattern
     * @param string $string String to test
     * @param string $message Message
     * @return void
     * @throws \SebastianBergmann\RecursionContext\InvalidArgumentException
     * @codeCoverageIgnore
     */
    static void assertMatchesRegularExpression(string $pattern, string $string, string $message = "") {
        static::assertThat($string, new RegularExpression($pattern), $message);
    }

    /**
     * Asserts that a string does not match a given regular expression.
     *
     * @param string $pattern Regex pattern
     * @param string $string String to test
     * @param string $message Message
     * @return void
     * @throws \SebastianBergmann\RecursionContext\InvalidArgumentException
     */
    static void assertDoesNotMatchRegularExpression(
        string $pattern,
        string $string,
        string $message = ""
    ) {
        static::assertThat(
            $string,
            new LogicalNot(
                new RegularExpression($pattern)
            ),
            $message
        );
    }

    /**
     * Asserts that a file does not exist.
     *
     * @param string $filename Filename
     * @param string $message Message
     * @return void
     * @throws \SebastianBergmann\RecursionContext\InvalidArgumentException
     * @codeCoverageIgnore
     */
    static void assertFileDoesNotExist(string $filename, string $message = "") {
        static::assertThat($filename, new LogicalNot(new FileExists()), $message);
    }

    /**
     * Asserts that a directory does not exist.
     *
     * @param string $directory Directory
     * @param string $message Message
     * @return void
     * @throws \SebastianBergmann\RecursionContext\InvalidArgumentException
     * @codeCoverageIgnore
     */
    static void assertDirectoryDoesNotExist(string $directory, string $message = "") {
        static::assertThat($directory, new LogicalNot(new DirectoryExists()), $message);
    }

    /**
     * Overrides SimpleTestCase::skipIf to provide a boolean return value
     *
     * @param bool $shouldSkip Whether the test should be skipped.
     * @param string $message The message to display.
     */
    bool skipIf(bool $shouldSkip, string $message = "") {
        if ($shouldSkip) {
            this.markTestSkipped($message);
        }

        return $shouldSkip;
    }

    /**
     * Helper method for tests that needs to use error_reporting()
     *
     * @param int $errorLevel value of error_reporting() that needs to use
     * @param callable $callable callable function that will receive asserts
     */
    void withErrorReporting(int $errorLevel, callable $callable) {
        $default = error_reporting();
        error_reporting($errorLevel);
        try {
            $callable();
        } finally {
            error_reporting($default);
        }
    }

    /**
     * Helper method for check deprecation methods
     *
     * @param callable $callable callable function that will receive asserts
     */
    void deprecated(callable $callable) {
        $duplicate = Configure::read("Error.allowDuplicateDeprecations");
        Configure::write("Error.allowDuplicateDeprecations", true);
        /** @var bool $deprecation */
        $deprecation = false;

        /**
         * @psalm-suppress InvalidArgument
         */
        $previousHandler = set_error_handler(
            bool ($code, $message, $file, $line, $context = null) use (&$previousHandler, &$deprecation) {
                if ($code == E_USER_DEPRECATED) {
                    $deprecation = true;

                    return true;
                }
                if ($previousHandler) {
                    return $previousHandler($code, $message, $file, $line, $context);
                }

                return false;
            }
        );
        try {
            $callable();
        } finally {
            restore_error_handler();
            if ($duplicate != Configure::read("Error.allowDuplicateDeprecations")) {
                Configure::write("Error.allowDuplicateDeprecations", $duplicate);
            }
        }
        this.assertTrue($deprecation, "Should have at least one deprecation warning");
    }

    /**
     * Setup the test case, backup the static object values so they can be restored.
     * Specifically backs up the contents of Configure and paths in App if they have
     * not already been backed up.
     */
    protected void setUp() {
        super.setUp();
        this.setupFixtures();

        if (!_configure) {
            _configure = Configure::read();
        }
        if (class_exists(Router::class, false)) {
            Router::reload();
        }

        EventManager::instance(new EventManager());
    }

    /**
     * teardown any static object changes and restore them.
     */
    protected void tearDown() {
        super.tearDown();
        this.teardownFixtures();

        if (_configure) {
            Configure::clear();
            Configure::write(_configure);
        }
        this.getTableLocator().clear();
        _configure = null;
        _tableLocator = null;
    }

    /**
     * Initialized and loads any use fixtures.
     */
    protected void setupFixtures() {
        $fixtureNames = this.getFixtures();

        if (!empty($fixtureNames) && static::$fixtureManager) {
            if (!this.autoFixtures) {
                deprecationWarning("`$autoFixtures` is deprecated and will be removed in 5.0.", 0);
            }
            if (this.dropTables) {
                deprecationWarning("`$dropTables` is deprecated and will be removed in 5.0.", 0);
            }
            // legacy fixtures are managed by FixtureInjector
            return;
        }

        this.fixtureStrategy = this.getFixtureStrategy();
        this.fixtureStrategy.setupTest($fixtureNames);
    }

    /**
     * Unloads any use fixtures.
     */
    protected void teardownFixtures() {
        if (this.fixtureStrategy) {
            this.fixtureStrategy.teardownTest();
            this.fixtureStrategy = null;
        }
    }

    /**
     * Returns fixture strategy used by these tests.
     *
     * @return uim.cake.TestSuite\Fixture\FixtureStrategyInterface
     */
    protected function getFixtureStrategy(): FixtureStrategyInterface
    {
        return new TruncateStrategy();
    }

    /**
     * Chooses which fixtures to load for a given test
     *
     * Each parameter is a model name that corresponds to a fixture, i.e~ "Posts", "Authors", etc.
     * Passing no parameters will cause all fixtures on the test case to load.
     *
     * @return void
     * @see uim.cake.TestSuite\TestCase::$autoFixtures
     * @throws \RuntimeException when no fixture manager is available.
     * @deprecated 4.3.0 Disabling auto-fixtures is deprecated and only available using FixtureInjector fixture system.
     */
    void loadFixtures() {
        if (this.autoFixtures) {
            throw new RuntimeException("Cannot use `loadFixtures()` with `$autoFixtures` enabled.");
        }
        if (static::$fixtureManager == null) {
            throw new RuntimeException("No fixture manager to load the test fixture");
        }

        $args = func_get_args();
        foreach ($args as $class) {
            static::$fixtureManager.loadSingle($class, null, this.dropTables);
        }

        if (empty($args)) {
            $autoFixtures = this.autoFixtures;
            this.autoFixtures = true;
            static::$fixtureManager.load(this);
            this.autoFixtures = $autoFixtures;
        }
    }

    /**
     * Load routes for the application.
     *
     * If no application class can be found an exception will be raised.
     * Routes for plugins will *not* be loaded. Use `loadPlugins()` or use
     * `Cake\TestSuite\IntegrationTestCaseTrait` to better simulate all routes
     * and plugins being loaded.
     *
     * @param array|null $appArgs Constructor parameters for the application class.
     * @return void
     * @since 4.0.1
     */
    void loadRoutes(?array $appArgs = null) {
        $appArgs = $appArgs ?? [rtrim(CONFIG, DIRECTORY_SEPARATOR)];
        /** @psalm-var class-string */
        $className = Configure::read("App.namespace") ~ "\\Application";
        try {
            $reflect = new ReflectionClass($className);
            /** @var uim.cake.routings.IRoutingApplication $app */
            $app = $reflect.newInstanceArgs($appArgs);
        } catch (ReflectionException $e) {
            throw new LogicException(sprintf("Cannot load '%s' to load routes from.", $className), 0, $e);
        }
        $builder = Router::createRouteBuilder("/");
        $app.routes($builder);
    }

    /**
     * Load plugins into a simulated application.
     *
     * Useful to test how plugins being loaded/not loaded interact with other
     * elements in UIM or applications.
     *
     * @param array<string, mixed> $plugins List of Plugins to load.
     * @return uim.cake.http.BaseApplication
     */
    function loadPlugins(array $plugins = null): BaseApplication
    {
        /** @var uim.cake.http.BaseApplication $app */
        $app = this.getMockForAbstractClass(
            BaseApplication::class,
            [""]
        );

        foreach ($plugins as $pluginName: aConfig) {
            if (is_array(aConfig)) {
                $app.addPlugin($pluginName, aConfig);
            } else {
                $app.addPlugin(aConfig);
            }
        }
        $app.pluginBootstrap();
        $builder = Router::createRouteBuilder("/");
        $app.pluginRoutes($builder);

        return $app;
    }

    /**
     * Remove plugins from the global plugin collection.
     *
     * Useful in test case teardown methods.
     *
     * @param array<string> $names A list of plugins you want to remove.
     */
    void removePlugins(array $names = null) {
        $collection = Plugin::getCollection();
        foreach ($names as $name) {
            $collection.remove($name);
        }
    }

    /**
     * Clear all plugins from the global plugin collection.
     *
     * Useful in test case teardown methods.
     */
    void clearPlugins() {
        Plugin::getCollection().clear();
    }

    /**
     * Asserts that a global event was fired. You must track events in your event manager for this assertion to work
     *
     * @param string aName Event name
     * @param uim.cake.events.EventManager|null $eventManager Event manager to check, defaults to global event manager
     * @param string $message Assertion failure message
     */
    void assertEventFired(string aName, ?EventManager $eventManager = null, string $message = "") {
        if (!$eventManager) {
            $eventManager = EventManager::instance();
        }
        this.assertThat($name, new EventFired($eventManager), $message);
    }

    /**
     * Asserts an event was fired with data
     *
     * If a third argument is passed, that value is used to compare with the value in $dataKey
     *
     * @param string aName Event name
     * @param string $dataKey Data key
     * @param mixed $dataValue Data value
     * @param uim.cake.events.EventManager|null $eventManager Event manager to check, defaults to global event manager
     * @param string $message Assertion failure message
     */
    void assertEventFiredWith(
        string aName,
        string $dataKey,
        $dataValue,
        ?EventManager $eventManager = null,
        string $message = ""
    ) {
        if (!$eventManager) {
            $eventManager = EventManager::instance();
        }
        this.assertThat($name, new EventFiredWith($eventManager, $dataKey, $dataValue), $message);
    }

    /**
     * Assert text equality, ignoring differences in newlines.
     * Helpful for doing cross platform tests of blocks of text.
     *
     * @param string $expected The expected value.
     * @param string $result The actual value.
     * @param string $message The message to use for failure.
     */
    void assertTextNotEquals(string $expected, string $result, string $message = "") {
        $expected = replace(["\r\n", "\r"], "\n", $expected);
        $result = replace(["\r\n", "\r"], "\n", $result);
        this.assertNotEquals($expected, $result, $message);
    }

    /**
     * Assert text equality, ignoring differences in newlines.
     * Helpful for doing cross platform tests of blocks of text.
     *
     * @param string $expected The expected value.
     * @param string $result The actual value.
     * @param string $message The message to use for failure.
     */
    void assertTextEquals(string $expected, string $result, string $message = "") {
        $expected = replace(["\r\n", "\r"], "\n", $expected);
        $result = replace(["\r\n", "\r"], "\n", $result);
        this.assertEquals($expected, $result, $message);
    }

    /**
     * Asserts that a string starts with a given prefix, ignoring differences in newlines.
     * Helpful for doing cross platform tests of blocks of text.
     *
     * @param string $prefix The prefix to check for.
     * @param string $string The string to search in.
     * @param string $message The message to use for failure.
     */
    void assertTextStartsWith(string $prefix, string $string, string $message = "") {
        $prefix = replace(["\r\n", "\r"], "\n", $prefix);
        $string = replace(["\r\n", "\r"], "\n", $string);
        this.assertStringStartsWith($prefix, $string, $message);
    }

    /**
     * Asserts that a string starts not with a given prefix, ignoring differences in newlines.
     * Helpful for doing cross platform tests of blocks of text.
     *
     * @param string $prefix The prefix to not find.
     * @param string $string The string to search.
     * @param string $message The message to use for failure.
     */
    void assertTextStartsNotWith(string $prefix, string $string, string $message = "") {
        $prefix = replace(["\r\n", "\r"], "\n", $prefix);
        $string = replace(["\r\n", "\r"], "\n", $string);
        this.assertStringStartsNotWith($prefix, $string, $message);
    }

    /**
     * Asserts that a string ends with a given prefix, ignoring differences in newlines.
     * Helpful for doing cross platform tests of blocks of text.
     *
     * @param string $suffix The suffix to find.
     * @param string $string The string to search.
     * @param string $message The message to use for failure.
     */
    void assertT:With(string $suffix, string $string, string $message = "") {
        $suffix = replace(["\r\n", "\r"], "\n", $suffix);
        $string = replace(["\r\n", "\r"], "\n", $string);
        this.assertStringEndsWith($suffix, $string, $message);
    }

    /**
     * Asserts that a string ends not with a given prefix, ignoring differences in newlines.
     * Helpful for doing cross platform tests of blocks of text.
     *
     * @param string $suffix The suffix to not find.
     * @param string $string The string to search.
     * @param string $message The message to use for failure.
     */
    void assertT:NotWith(string $suffix, string $string, string $message = "") {
        $suffix = replace(["\r\n", "\r"], "\n", $suffix);
        $string = replace(["\r\n", "\r"], "\n", $string);
        this.assertStringEndsNotWith($suffix, $string, $message);
    }

    /**
     * Assert that a string contains another string, ignoring differences in newlines.
     * Helpful for doing cross platform tests of blocks of text.
     *
     * @param string $needle The string to search for.
     * @param string $haystack The string to search through.
     * @param string $message The message to display on failure.
     * @param bool $ignoreCase Whether the search should be case-sensitive.
     */
    void assertTextContains(
        string $needle,
        string $haystack,
        string $message = "",
        bool $ignoreCase = false
    ) {
        $needle = replace(["\r\n", "\r"], "\n", $needle);
        $haystack = replace(["\r\n", "\r"], "\n", $haystack);

        if ($ignoreCase) {
            this.assertStringContainsStringIgnoringCase($needle, $haystack, $message);
        } else {
            this.assertStringContainsString($needle, $haystack, $message);
        }
    }

    /**
     * Assert that a text doesn"t contain another text, ignoring differences in newlines.
     * Helpful for doing cross platform tests of blocks of text.
     *
     * @param string $needle The string to search for.
     * @param string $haystack The string to search through.
     * @param string $message The message to display on failure.
     * @param bool $ignoreCase Whether the search should be case-sensitive.
     */
    void assertTextNotContains(
        string $needle,
        string $haystack,
        string $message = "",
        bool $ignoreCase = false
    ) {
        $needle = replace(["\r\n", "\r"], "\n", $needle);
        $haystack = replace(["\r\n", "\r"], "\n", $haystack);

        if ($ignoreCase) {
            this.assertStringNotContainsStringIgnoringCase($needle, $haystack, $message);
        } else {
            this.assertStringNotContainsString($needle, $haystack, $message);
        }
    }

    /**
     * Assert that a string matches SQL with db-specific characters like quotes removed.
     *
     * @param string $expected The expected sql
     * @param string $actual The sql to compare
     * @param string $message The message to display on failure
     */
    void assertEqualsSql(
        string $expected,
        string $actual,
        string $message = ""
    ) {
        this.assertEquals($expected, preg_replace("/[`"\[\]]/", "", $actual), $message);
    }

    /**
     * Assertion for comparing a regex pattern against a query having its identifiers
     * quoted. It accepts queries quoted with the characters `<` and `>`. If the third
     * parameter is set to true, it will alter the pattern to both accept quoted and
     * unquoted queries
     *
     * @param string $pattern The expected sql pattern
     * @param string $actual The sql to compare
     * @param bool $optional Whether quote characters (marked with <>) are optional
     */
    void assertRegExpSql(string $pattern, string $actual, bool $optional = false) {
        $optional = $optional ? "?" : "";
        $pattern = replace("<", "[`"\[]" ~ $optional, $pattern);
        $pattern = replace(">", "[`"\]]" ~ $optional, $pattern);
        this.assertMatchesRegularExpression("#" ~ $pattern ~ "#", $actual);
    }

    /**
     * Asserts HTML tags.
     *
     * Takes an array $expected and generates a regex from it to match the provided $string.
     * Samples for $expected:
     *
     * Checks for an input tag with a name attribute (contains any non-empty value) and an id
     * attribute that contains "my-input":
     *
     * ```
     * ["input": ["name", "id": "my-input"]]
     * ```
     *
     * Checks for two p elements with some text in them:
     *
     * ```
     * [
     *   ["p": true],
     *   "textA",
     *   "/p",
     *   ["p": true],
     *   "textB",
     *   "/p"
     * ]
     * ```
     *
     * You can also specify a pattern expression as part of the attribute values, or the tag
     * being defined, if you prepend the value with preg: and enclose it with slashes, like so:
     *
     * ```
     * [
     *   ["input": ["name", "id": "preg:/FieldName\d+/"]],
     *   "preg:/My\s+field/"
     * ]
     * ```
     *
     * Important: This bool is very forgiving about whitespace and also accepts any
     * permutation of attribute order. It will also allow whitespace between specified tags.
     *
     * @param array $expected An array, see above
     * @param string $string An HTML/XHTML/XML string
     * @param bool $fullDebug Whether more verbose output should be used.
     */
    bool assertHtml(array $expected, string $string, bool $fullDebug = false) {
        $regex = null;
        $normalized = null;
        foreach ($expected as $key: $val) {
            if (!is_numeric($key)) {
                $normalized[] = [$key: $val];
            } else {
                $normalized[] = $val;
            }
        }
        $i = 0;
        foreach ($normalized as $tags) {
            if (!is_array($tags)) {
                $tags = (string)$tags;
            }
            $i++;
            if (is_string($tags) && $tags[0] == "<") {
                /** @psalm-suppress InvalidArrayOffset */
                $tags = [substr($tags, 1): []];
            } elseif (is_string($tags)) {
                $tagsTrimmed = preg_replace("/\s+/m", "", $tags);

                if (preg_match("/^\*?\//", $tags, $match) && $tagsTrimmed != "//") {
                    $prefix = ["", ""];

                    if ($match[0] == "*/") {
                        $prefix = ["Anything, ", ".*?"];
                    }
                    $regex[] = [
                        sprintf("%sClose %s tag", $prefix[0], substr($tags, strlen($match[0]))),
                        sprintf("%s\s*<[\s]*\/[\s]*%s[\s]*>[\n\r]*", $prefix[1], substr($tags, strlen($match[0]))),
                        $i,
                    ];
                    continue;
                }
                if (!empty($tags) && preg_match("/^preg\:\/(.+)\/$/i", $tags, $matches)) {
                    $tags = $matches[1];
                    $type = "Regex matches";
                } else {
                    $tags = "\s*" ~ preg_quote($tags, "/");
                    $type = "Text equals";
                }
                $regex[] = [
                    sprintf("%s '%s'", $type, $tags),
                    $tags,
                    $i,
                ];
                continue;
            }
            foreach ($tags as $tag: $attributes) {
                /** @psalm-suppress PossiblyFalseArgument */
                $regex[] = [
                    sprintf("Open %s tag", $tag),
                    sprintf("[\s]*<%s", preg_quote($tag, "/")),
                    $i,
                ];
                if ($attributes == true) {
                    $attributes = null;
                }
                $attrs = null;
                $explanations = null;
                $i = 1;
                foreach ($attributes as $attr: $val) {
                    if (is_numeric($attr) && preg_match("/^preg\:\/(.+)\/$/i", (string)$val, $matches)) {
                        $attrs[] = $matches[1];
                        $explanations[] = sprintf("Regex '%s' matches", $matches[1]);
                        continue;
                    }
                    $val = (string)$val;

                    $quotes = "["\"]";
                    if (is_numeric($attr)) {
                        $attr = $val;
                        $val = ".+?";
                        $explanations[] = sprintf("Attribute '%s' present", $attr);
                    } elseif (!empty($val) && preg_match("/^preg\:\/(.+)\/$/i", $val, $matches)) {
                        $val = replace(
                            [".*", ".+"],
                            [".*?", ".+?"],
                            $matches[1]
                        );
                        $quotes = $val != $matches[1] ? "["\"]" : "["\"]?";

                        $explanations[] = sprintf("Attribute '%s' matches '%s'", $attr, $val);
                    } else {
                        $explanations[] = sprintf("Attribute '%s' == '%s'", $attr, $val);
                        $val = preg_quote($val, "/");
                    }
                    $attrs[] = "[\s]+" ~ preg_quote($attr, "/") ~ "=" ~ $quotes . $val . $quotes;
                    $i++;
                }
                if ($attrs) {
                    $regex[] = [
                        "explains": $explanations,
                        "attrs": $attrs,
                    ];
                }
                /** @psalm-suppress PossiblyFalseArgument */
                $regex[] = [
                    sprintf("End %s tag", $tag),
                    "[\s]*\/?[\s]*>[\n\r]*",
                    $i,
                ];
            }
        }
        /**
         * @var array<string, mixed> $assertion
         */
        foreach ($regex as $i: $assertion) {
            $matches = false;
            if (isset($assertion["attrs"])) {
                $string = _assertAttributes($assertion, $string, $fullDebug, $regex);
                if ($fullDebug == true && $string == false) {
                    debug($string, true);
                    debug($regex, true);
                }
                continue;
            }

            // If "attrs" is not present then the array is just a regular int-offset one
            /** @psalm-suppress PossiblyUndefinedArrayOffset */
            [$description, $expressions, $itemNum] = $assertion;
            $expression = "";
            foreach ((array)$expressions as $expression) {
                $expression = sprintf("/^%s/s", $expression);
                if (preg_match($expression, $string, $match)) {
                    $matches = true;
                    $string = substr($string, strlen($match[0]));
                    break;
                }
            }
            if (!$matches) {
                if ($fullDebug == true) {
                    debug($string);
                    debug($regex);
                }
                this.assertMatchesRegularExpression(
                    $expression,
                    $string,
                    sprintf("Item #%d / regex #%d failed: %s", $itemNum, $i, $description)
                );

                return false;
            }
        }

        this.assertTrue(true, '%s');

        return true;
    }

    /**
     * Check the attributes as part of an assertTags() check.
     *
     * @param array<string, mixed> $assertions Assertions to run.
     * @param string $string The HTML string to check.
     * @param bool $fullDebug Whether more verbose output should be used.
     * @param array|string $regex Full regexp from `assertHtml`
     * @return string|false
     */
    protected function _assertAttributes(array $assertions, string $string, bool $fullDebug = false, $regex = "") {
        $asserts = $assertions["attrs"];
        $explains = $assertions["explains"];
        do {
            $matches = false;
            $j = null;
            foreach ($asserts as $j: $assert) {
                if (preg_match(sprintf("/^%s/s", $assert), $string, $match)) {
                    $matches = true;
                    $string = substr($string, strlen($match[0]));
                    array_splice($asserts, $j, 1);
                    array_splice($explains, $j, 1);
                    break;
                }
            }
            if ($matches == false) {
                if ($fullDebug == true) {
                    debug($string);
                    debug($regex);
                }
                this.assertTrue(false, "Attribute did not match. Was expecting " ~ $explains[$j]);
            }
            $len = count($asserts);
        } while ($len > 0);

        return $string;
    }

    /**
     * Normalize a path for comparison.
     *
     * @param string $path Path separated by "/" slash.
     * @return string Normalized path separated by DIRECTORY_SEPARATOR.
     */
    protected string _normalizePath(string $path) {
        return replace("/", DIRECTORY_SEPARATOR, $path);
    }

// phpcs:disable

    /**
     * Compatibility function to test if a value is between an acceptable range.
     *
     * @param float $expected
     * @param float $result
     * @param float $margin the rage of acceptation
     * @param string $message the text to display if the assertion is not correct
     * @return void
     */
    protected static function assertWithinRange($expected, $result, $margin, $message = "") {
        $upper = $result + $margin;
        $lower = $result - $margin;
        static::assertTrue(($expected <= $upper) && ($expected >= $lower), $message);
    }

    /**
     * Compatibility function to test if a value is not between an acceptable range.
     *
     * @param float $expected
     * @param float $result
     * @param float $margin the rage of acceptation
     * @param string $message the text to display if the assertion is not correct
     * @return void
     */
    protected static function assertNotWithinRange($expected, $result, $margin, $message = "") {
        $upper = $result + $margin;
        $lower = $result - $margin;
        static::assertTrue(($expected > $upper) || ($expected < $lower), $message);
    }

    /**
     * Compatibility function to test paths.
     *
     * @param string $expected
     * @param string $result
     * @param string $message the text to display if the assertion is not correct
     * @return void
     */
    protected static function assertPathEquals($expected, $result, $message = "") {
        $expected = replace(DIRECTORY_SEPARATOR, "/", $expected);
        $result = replace(DIRECTORY_SEPARATOR, "/", $result);
        static::assertEquals($expected, $result, $message);
    }

    /**
     * Compatibility function for skipping.
     *
     * @param bool $condition Condition to trigger skipping
     * @param string $message Message for skip
     */
    protected bool skipUnless($condition, $message = "") {
        if (!$condition) {
            this.markTestSkipped($message);
        }

        return $condition;
    }

// phpcs:enable

    /**
     * Mock a model, maintain fixtures and table association
     *
     * @param string $alias The model to get a mock for.
     * @param array<string> $methods The list of methods to mock
     * @param array<string, mixed> $options The config data for the mock"s constructor.
     * @throws uim.cake.orm.exceptions.MissingTableClassException
     * @return uim.cake.orm.Table|\PHPUnit\Framework\MockObject\MockObject
     */
    function getMockForModel(string $alias, array $methods = null, STRINGAA someOptions = null) {
        $className = _getTableClassName($alias, $options);
        $connectionName = $className::defaultConnectionName();
        $connection = ConnectionManager::get($connectionName);

        $locator = this.getTableLocator();

        [, $baseClass] = pluginSplit($alias);
        $options += ["alias": $baseClass, "connection": $connection];
        $options += $locator.getConfig($alias);
        $reflection = new ReflectionClass($className);
        $classMethods = array_map(function ($method) {
            return $method.name;
        }, $reflection.getMethods());

        $existingMethods = array_intersect($classMethods, $methods);
        $nonExistingMethods = array_diff($methods, $existingMethods);

        $builder = this.getMockBuilder($className)
            .setConstructorArgs([$options]);

        if ($existingMethods || !$nonExistingMethods) {
            $builder.onlyMethods($existingMethods);
        }

        if ($nonExistingMethods) {
            $builder.addMethods($nonExistingMethods);
        }

        /** @var DORMTable $mock */
        $mock = $builder.getMock();

        if (empty($options["entityClass"]) && $mock.getEntityClass() == Entity::class) {
            $parts = explode("\\", $className);
            $entityAlias = Inflector::classify(Inflector::underscore(substr(array_pop($parts), 0, -5)));
            $entityClass = implode("\\", array_slice($parts, 0, -1)) ~ "\\Entity\\" ~ $entityAlias;
            if (class_exists($entityClass)) {
                $mock.setEntityClass($entityClass);
            }
        }

        if (stripos($mock.getTable(), "mock") == 0) {
            $mock.setTable(Inflector::tableize($baseClass));
        }

        $locator.set($baseClass, $mock);
        $locator.set($alias, $mock);

        return $mock;
    }

    /**
     * Gets the class name for the table.
     *
     * @param string $alias The model to get a mock for.
     * @param array<string, mixed> $options The config data for the mock"s constructor.
     * @return string
     * @throws uim.cake.orm.exceptions.MissingTableClassException
     * @psalm-return class-string<uim.cake.orm.Table>
     */
    protected string _getTableClassName(string $alias, STRINGAA someOptions) {
        if (empty($options["className"])) {
            $class = Inflector::camelize($alias);
            /** @psalm-var class-string<uim.cake.orm.Table>|null */
            $className = App::className($class, "Model/Table", "Table");
            if (!$className) {
                throw new MissingTableClassException([$alias]);
            }
            $options["className"] = $className;
        }

        return $options["className"];
    }

    /**
     * Set the app namespace
     *
     * @param string $appNamespace The app namespace, defaults to "TestApp".
     * @return string|null The previous app namespace or null if not set.
     */
    static Nullable!string setAppNamespace(string $appNamespace = "TestApp") {
        $previous = Configure::read("App.namespace");
        Configure::write("App.namespace", $appNamespace);

        return $previous;
    }

    /**
     * Adds a fixture to this test case.
     *
     * Examples:
     * - core.Tags
     * - app.MyRecords
     * - plugin.MyPluginName.MyModelName
     *
     * Use this method inside your test cases" {@link getFixtures()} method
     * to build up the fixture list.
     *
     * @param string $fixture Fixture
     * @return this
     */
    protected function addFixture(string $fixture) {
        this.fixtures[] = $fixture;

        return this;
    }

    /**
     * Get the fixtures this test should use.
     *
     * @return array<string>
     */
    string[] getFixtures() {
        return this.fixtures;
    }
}
