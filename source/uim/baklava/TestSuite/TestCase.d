

/**

 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         1.2.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.TestSuite;

import uim.baklava.core.App;
import uim.baklava.core.Configure;
import uim.baklava.core.Plugin;
import uim.baklava.Datasource\ConnectionManager;
import uim.baklava.events\EventManager;
import uim.baklava.https\BaseApplication;
import uim.baklava.orm.Entity;
import uim.baklava.orm.Exception\MissingTableClassException;
import uim.baklava.orm.Locator\LocatorAwareTrait;
import uim.baklava.Routing\Router;
import uim.baklava.TestSuite\Constraint\EventFired;
import uim.baklava.TestSuite\Constraint\EventFiredWith;
import uim.baklava.TestSuite\Fixture\FixtureStrategyInterface;
import uim.baklava.TestSuite\Fixture\TruncateStrategy;
import uim.baklava.utikities.Inflector;
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
     * @var \Cake\TestSuite\Fixture\FixtureManager|null
     */
    static $fixtureManager;

    /**
     * Fixtures used by this test case.
     *
     * @var array<string>
     */
    protected $fixtures = [];

    /**
     * By default, all fixtures attached to this class will be truncated and reloaded after each test.
     * Set this to false to handle manually
     *
     * @var bool
     * @deprecated 4.3.0 autoFixtures is only used by deprecated fixture features.
     *   This property will be removed in 5.0
     */
    public $autoFixtures = true;

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
    public $dropTables = false;

    /**
     * @var \Cake\TestSuite\Fixture\FixtureStrategyInterface|null
     */
    protected $fixtureStrategy = null;

    /**
     * Configure values to restore at end of test.
     *
     * @var array
     */
    protected $_configure = [];

    /**
     * Asserts that a string matches a given regular expression.
     *
     * @param string $pattern Regex pattern
     * @param string $string String to test
     * @param string myMessage Message
     * @return void
     * @throws \SebastianBergmann\RecursionContext\InvalidArgumentException
     * @codeCoverageIgnore
     */
    static function assertMatchesRegularExpression(string $pattern, string $string, string myMessage = ''): void
    {
        static::assertThat($string, new RegularExpression($pattern), myMessage);
    }

    /**
     * Asserts that a string does not match a given regular expression.
     *
     * @param string $pattern Regex pattern
     * @param string $string String to test
     * @param string myMessage Message
     * @return void
     * @throws \SebastianBergmann\RecursionContext\InvalidArgumentException
     */
    static function assertDoesNotMatchRegularExpression(
        string $pattern,
        string $string,
        string myMessage = ''
    ): void {
        static::assertThat(
            $string,
            new LogicalNot(
                new RegularExpression($pattern)
            ),
            myMessage
        );
    }

    /**
     * Asserts that a file does not exist.
     *
     * @param string myfilename Filename
     * @param string myMessage Message
     * @return void
     * @throws \SebastianBergmann\RecursionContext\InvalidArgumentException
     * @codeCoverageIgnore
     */
    static function assertFileDoesNotExist(string myfilename, string myMessage = ''): void
    {
        static::assertThat(myfilename, new LogicalNot(new FileExists()), myMessage);
    }

    /**
     * Asserts that a directory does not exist.
     *
     * @param string $directory Directory
     * @param string myMessage Message
     * @return void
     * @throws \SebastianBergmann\RecursionContext\InvalidArgumentException
     * @codeCoverageIgnore
     */
    static function assertDirectoryDoesNotExist(string $directory, string myMessage = ''): void
    {
        static::assertThat($directory, new LogicalNot(new DirectoryExists()), myMessage);
    }

    /**
     * Overrides SimpleTestCase::skipIf to provide a boolean return value
     *
     * @param bool $shouldSkip Whether the test should be skipped.
     * @param string myMessage The message to display.
     * @return bool
     */
    function skipIf(bool $shouldSkip, string myMessage = ''): bool
    {
        if ($shouldSkip) {
            this.markTestSkipped(myMessage);
        }

        return $shouldSkip;
    }

    /**
     * Helper method for tests that needs to use error_reporting()
     *
     * @param int myErrorLevel value of error_reporting() that needs to use
     * @param callable $callable callable function that will receive asserts
     * @return void
     */
    function withErrorReporting(int myErrorLevel, callable $callable): void
    {
        $default = error_reporting();
        error_reporting(myErrorLevel);
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
     * @return void
     */
    function deprecated(callable $callable): void
    {
        $duplicate = Configure::read('Error.allowDuplicateDeprecations');
        Configure.write('Error.allowDuplicateDeprecations', true);
        /** @var bool $deprecation */
        $deprecation = false;

        /**
         * @psalm-suppress InvalidArgument
         */
        $previousHandler = set_error_handler(
            function ($code, myMessage, myfile, $line, $context = null) use (&$previousHandler, &$deprecation) {
                if ($code == E_USER_DEPRECATED) {
                    $deprecation = true;

                    return;
                }
                if ($previousHandler) {
                    return $previousHandler($code, myMessage, myfile, $line, $context);
                }

                return false;
            }
        );
        try {
            $callable();
        } finally {
            restore_error_handler();
            if ($duplicate !== Configure::read('Error.allowDuplicateDeprecations')) {
                Configure.write('Error.allowDuplicateDeprecations', $duplicate);
            }
        }
        this.assertTrue($deprecation, 'Should have at least one deprecation warning');
    }

    /**
     * Setup the test case, backup the static object values so they can be restored.
     * Specifically backs up the contents of Configure and paths in App if they have
     * not already been backed up.
     *
     * @return void
     */
    protected auto setUp(): void
    {
        super.setUp();
        this.setupFixtures();

        if (!this._configure) {
            this._configure = Configure::read();
        }
        if (class_exists(Router::class, false)) {
            Router::reload();
        }

        EventManager::instance(new EventManager());
    }

    /**
     * teardown any static object changes and restore them.
     *
     * @return void
     */
    protected auto tearDown(): void
    {
        super.tearDown();
        this.teardownFixtures();

        if (this._configure) {
            Configure::clear();
            Configure.write(this._configure);
        }
        this.getTableLocator().clear();
        this._configure = [];
        this._tableLocator = null;
    }

    /**
     * Initialized and loads any use fixtures.
     *
     * @return void
     */
    protected auto setupFixtures(): void
    {
        $fixtureNames = this.getFixtures();

        if (!empty($fixtureNames) && static::$fixtureManager) {
            if (!this.autoFixtures) {
                deprecationWarning('`$autoFixtures` is deprecated and will be removed in 5.0.', 0);
            }
            if (this.dropTables) {
                deprecationWarning('`$dropTables` is deprecated and will be removed in 5.0.', 0);
            }
            // legacy fixtures are managed by FixtureInjector
            return;
        }

        this.fixtureStrategy = this.getFixtureStrategy();
        this.fixtureStrategy.setupTest($fixtureNames);
    }

    /**
     * Unloads any use fixtures.
     *
     * @return void
     */
    protected auto teardownFixtures(): void
    {
        if (this.fixtureStrategy) {
            this.fixtureStrategy.teardownTest();
            this.fixtureStrategy = null;
        }
    }

    /**
     * Returns fixture strategy used by these tests.
     *
     * @return \Cake\TestSuite\Fixture\FixtureStrategyInterface
     */
    protected auto getFixtureStrategy(): FixtureStrategyInterface
    {
        return new TruncateStrategy();
    }

    /**
     * Chooses which fixtures to load for a given test
     *
     * Each parameter is a model name that corresponds to a fixture, i.e. 'Posts', 'Authors', etc.
     * Passing no parameters will cause all fixtures on the test case to load.
     *
     * @return void
     * @see \Cake\TestSuite\TestCase::$autoFixtures
     * @throws \RuntimeException when no fixture manager is available.
     * @deprecated 4.3.0 Disabling auto-fixtures is deprecated and only available using FixtureInjector fixture system.
     */
    function loadFixtures(): void
    {
        if (this.autoFixtures) {
            throw new RuntimeException('Cannot use `loadFixtures()` with `$autoFixtures` enabled.');
        }
        if (static::$fixtureManager === null) {
            throw new RuntimeException('No fixture manager to load the test fixture');
        }

        $args = func_get_args();
        foreach ($args as myClass) {
            static::$fixtureManager.loadSingle(myClass, null, this.dropTables);
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
    function loadRoutes(?array $appArgs = null): void
    {
        $appArgs = $appArgs ?? [rtrim(CONFIG, DIRECTORY_SEPARATOR)];
        /** @psalm-var class-string */
        myClassName = Configure::read('App.module') . '\\Application';
        try {
            $reflect = new ReflectionClass(myClassName);
            /** @var \Cake\Routing\RoutingApplicationInterface $app */
            $app = $reflect.newInstanceArgs($appArgs);
        } catch (ReflectionException $e) {
            throw new LogicException(sprintf('Cannot load "%s" to load routes from.', myClassName), 0, $e);
        }
        myBuilder = Router::createRouteBuilder('/');
        $app.routes(myBuilder);
    }

    /**
     * Load plugins into a simulated application.
     *
     * Useful to test how plugins being loaded/not loaded interact with other
     * elements in CakePHP or applications.
     *
     * @param array<string, mixed> myPlugins List of Plugins to load.
     * @return \Cake\Http\BaseApplication
     */
    function loadPlugins(array myPlugins = []): BaseApplication
    {
        /** @var \Cake\Http\BaseApplication $app */
        $app = this.getMockForAbstractClass(
            BaseApplication::class,
            ['']
        );

        foreach (myPlugins as myPluginName => myConfig) {
            if (is_array(myConfig)) {
                $app.addPlugin(myPluginName, myConfig);
            } else {
                $app.addPlugin(myConfig);
            }
        }
        $app.pluginBootstrap();
        myBuilder = Router::createRouteBuilder('/');
        $app.pluginRoutes(myBuilder);

        return $app;
    }

    /**
     * Remove plugins from the global plugin collection.
     *
     * Useful in test case teardown methods.
     *
     * @param array<string> myNames A list of plugins you want to remove.
     * @return void
     */
    function removePlugins(array myNames = []): void
    {
        myCollection = Plugin::getCollection();
        foreach (myNames as myName) {
            myCollection.remove(myName);
        }
    }

    /**
     * Clear all plugins from the global plugin collection.
     *
     * Useful in test case teardown methods.
     *
     * @return void
     */
    function clearPlugins(): void
    {
        Plugin::getCollection().clear();
    }

    /**
     * Asserts that a global event was fired. You must track events in your event manager for this assertion to work
     *
     * @param string myName Event name
     * @param \Cake\Event\EventManager|null myEventManager Event manager to check, defaults to global event manager
     * @param string myMessage Assertion failure message
     * @return void
     */
    function assertEventFired(string myName, ?EventManager myEventManager = null, string myMessage = ''): void
    {
        if (!myEventManager) {
            myEventManager = EventManager::instance();
        }
        this.assertThat(myName, new EventFired(myEventManager), myMessage);
    }

    /**
     * Asserts an event was fired with data
     *
     * If a third argument is passed, that value is used to compare with the value in myDataKey
     *
     * @param string myName Event name
     * @param string myDataKey Data key
     * @param mixed myDataValue Data value
     * @param \Cake\Event\EventManager|null myEventManager Event manager to check, defaults to global event manager
     * @param string myMessage Assertion failure message
     * @return void
     */
    void assertEventFiredWith(
        string myName,
        string myDataKey,
        myDataValue,
        ?EventManager myEventManager = null,
        string myMessage = ''
    ) {
        if (!myEventManager) {
            myEventManager = EventManager::instance();
        }
        this.assertThat(myName, new EventFiredWith(myEventManager, myDataKey, myDataValue), myMessage);
    }

    /**
     * Assert text equality, ignoring differences in newlines.
     * Helpful for doing cross platform tests of blocks of text.
     *
     * @param string $expected The expected value.
     * @param string myResult The actual value.
     * @param string myMessage The message to use for failure.
     * @return void
     */
    void assertTextNotEquals(string $expected, string myResult, string myMessage = '') {
        $expected = str_replace(["\r\n", "\r"], "\n", $expected);
        myResult = str_replace(["\r\n", "\r"], "\n", myResult);
        this.assertNotEquals($expected, myResult, myMessage);
    }

    /**
     * Assert text equality, ignoring differences in newlines.
     * Helpful for doing cross platform tests of blocks of text.
     *
     * @param string $expected The expected value.
     * @param string myResult The actual value.
     * @param string myMessage The message to use for failure.
     * @return void
     */
    void assertTextEquals(string $expected, string myResult, string myMessage = '') {
        $expected = str_replace(["\r\n", "\r"], "\n", $expected);
        myResult = str_replace(["\r\n", "\r"], "\n", myResult);
        this.assertEquals($expected, myResult, myMessage);
    }

    /**
     * Asserts that a string starts with a given prefix, ignoring differences in newlines.
     * Helpful for doing cross platform tests of blocks of text.
     *
     * @param string $prefix The prefix to check for.
     * @param string $string The string to search in.
     * @param string myMessage The message to use for failure.
     * @return void
     */
    void assertTextStartsWith(string $prefix, string $string, string myMessage = '') {
        $prefix = str_replace(["\r\n", "\r"], "\n", $prefix);
        $string = str_replace(["\r\n", "\r"], "\n", $string);
        this.assertStringStartsWith($prefix, $string, myMessage);
    }

    /**
     * Asserts that a string starts not with a given prefix, ignoring differences in newlines.
     * Helpful for doing cross platform tests of blocks of text.
     *
     * @param string $prefix The prefix to not find.
     * @param string $string The string to search.
     * @param string myMessage The message to use for failure.
     * @return void
     */
    void assertTextStartsNotWith(string $prefix, string $string, string myMessage = '') {
        $prefix = str_replace(["\r\n", "\r"], "\n", $prefix);
        $string = str_replace(["\r\n", "\r"], "\n", $string);
        this.assertStringStartsNotWith($prefix, $string, myMessage);
    }

    /**
     * Asserts that a string ends with a given prefix, ignoring differences in newlines.
     * Helpful for doing cross platform tests of blocks of text.
     *
     * @param string $suffix The suffix to find.
     * @param string $string The string to search.
     * @param string myMessage The message to use for failure.
     * @return void
     */
    void assertTextEndsWith(string $suffix, string $string, string myMessage = '') {
        $suffix = str_replace(["\r\n", "\r"], "\n", $suffix);
        $string = str_replace(["\r\n", "\r"], "\n", $string);
        this.assertStringEndsWith($suffix, $string, myMessage);
    }

    /**
     * Asserts that a string ends not with a given prefix, ignoring differences in newlines.
     * Helpful for doing cross platform tests of blocks of text.
     *
     * @param string $suffix The suffix to not find.
     * @param string $string The string to search.
     * @param string myMessage The message to use for failure.
     * @return void
     */
    void assertTextEndsNotWith(string $suffix, string $string, string myMessage = '') {
        $suffix = str_replace(["\r\n", "\r"], "\n", $suffix);
        $string = str_replace(["\r\n", "\r"], "\n", $string);
        this.assertStringEndsNotWith($suffix, $string, myMessage);
    }

    /**
     * Assert that a string contains another string, ignoring differences in newlines.
     * Helpful for doing cross platform tests of blocks of text.
     *
     * @param string $needle The string to search for.
     * @param string $haystack The string to search through.
     * @param string myMessage The message to display on failure.
     * @param bool $ignoreCase Whether the search should be case-sensitive.
     * @return void
     */
    void assertTextContains(
        string $needle,
        string $haystack,
        string myMessage = '',
        bool $ignoreCase = false
    ) {
        $needle = str_replace(["\r\n", "\r"], "\n", $needle);
        $haystack = str_replace(["\r\n", "\r"], "\n", $haystack);

        if ($ignoreCase) {
            this.assertStringContainsStringIgnoringCase($needle, $haystack, myMessage);
        } else {
            this.assertStringContainsString($needle, $haystack, myMessage);
        }
    }

    /**
     * Assert that a text doesn't contain another text, ignoring differences in newlines.
     * Helpful for doing cross platform tests of blocks of text.
     *
     * @param string $needle The string to search for.
     * @param string $haystack The string to search through.
     * @param string myMessage The message to display on failure.
     * @param bool $ignoreCase Whether the search should be case-sensitive.
     * @return void
     */
    function assertTextNotContains(
        string $needle,
        string $haystack,
        string myMessage = '',
        bool $ignoreCase = false
    ): void {
        $needle = str_replace(["\r\n", "\r"], "\n", $needle);
        $haystack = str_replace(["\r\n", "\r"], "\n", $haystack);

        if ($ignoreCase) {
            this.assertStringNotContainsStringIgnoringCase($needle, $haystack, myMessage);
        } else {
            this.assertStringNotContainsString($needle, $haystack, myMessage);
        }
    }

    /**
     * Assert that a string matches SQL with db-specific characters like quotes removed.
     *
     * @param string $expected The expected sql
     * @param string $actual The sql to compare
     * @param string myMessage The message to display on failure
     * @return void
     */
    function assertEqualsSql(
        string $expected,
        string $actual,
        string myMessage = ''
    ): void {
        this.assertEquals($expected, preg_replace('/[`"\[\]]/', '', $actual), myMessage);
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
     * @return void
     */
    function assertRegExpSql(string $pattern, string $actual, bool $optional = false): void
    {
        $optional = $optional ? '?' : '';
        $pattern = str_replace('<', '[`"\[]' . $optional, $pattern);
        $pattern = str_replace('>', '[`"\]]' . $optional, $pattern);
        this.assertMatchesRegularExpression('#' . $pattern . '#', $actual);
    }

    /**
     * Asserts HTML tags.
     *
     * Takes an array $expected and generates a regex from it to match the provided $string.
     * Samples for $expected:
     *
     * Checks for an input tag with a name attribute (contains any non-empty value) and an id
     * attribute that contains 'my-input':
     *
     * ```
     * ['input' => ['name', 'id' => 'my-input']]
     * ```
     *
     * Checks for two p elements with some text in them:
     *
     * ```
     * [
     *   ['p' => true],
     *   'textA',
     *   '/p',
     *   ['p' => true],
     *   'textB',
     *   '/p'
     * ]
     * ```
     *
     * You can also specify a pattern expression as part of the attribute values, or the tag
     * being defined, if you prepend the value with preg: and enclose it with slashes, like so:
     *
     * ```
     * [
     *   ['input' => ['name', 'id' => 'preg:/FieldName\d+/']],
     *   'preg:/My\s+field/'
     * ]
     * ```
     *
     * Important: This function is very forgiving about whitespace and also accepts any
     * permutation of attribute order. It will also allow whitespace between specified tags.
     *
     * @param array $expected An array, see above
     * @param string $string An HTML/XHTML/XML string
     * @param bool $fullDebug Whether more verbose output should be used.
     * @return bool
     */
    function assertHtml(array $expected, string $string, bool $fullDebug = false): bool
    {
        $regex = [];
        $normalized = [];
        foreach ($expected as myKey => $val) {
            if (!is_numeric(myKey)) {
                $normalized[] = [myKey => $val];
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
            if (is_string($tags) && $tags[0] === '<') {
                /** @psalm-suppress InvalidArrayOffset */
                $tags = [substr($tags, 1) => []];
            } elseif (is_string($tags)) {
                $tagsTrimmed = preg_replace('/\s+/m', '', $tags);

                if (preg_match('/^\*?\//', $tags, $match) && $tagsTrimmed !== '//') {
                    $prefix = ['', ''];

                    if ($match[0] === '*/') {
                        $prefix = ['Anything, ', '.*?'];
                    }
                    $regex[] = [
                        sprintf('%sClose %s tag', $prefix[0], substr($tags, strlen($match[0]))),
                        sprintf('%s\s*<[\s]*\/[\s]*%s[\s]*>[\n\r]*', $prefix[1], substr($tags, strlen($match[0]))),
                        $i,
                    ];
                    continue;
                }
                if (!empty($tags) && preg_match('/^preg\:\/(.+)\/$/i', $tags, $matches)) {
                    $tags = $matches[1];
                    myType = 'Regex matches';
                } else {
                    $tags = '\s*' . preg_quote($tags, '/');
                    myType = 'Text equals';
                }
                $regex[] = [
                    sprintf('%s "%s"', myType, $tags),
                    $tags,
                    $i,
                ];
                continue;
            }
            foreach ($tags as $tag => $attributes) {
                /** @psalm-suppress PossiblyFalseArgument */
                $regex[] = [
                    sprintf('Open %s tag', $tag),
                    sprintf('[\s]*<%s', preg_quote($tag, '/')),
                    $i,
                ];
                if ($attributes === true) {
                    $attributes = [];
                }
                $attrs = [];
                $explanations = [];
                $i = 1;
                foreach ($attributes as $attr => $val) {
                    if (is_numeric($attr) && preg_match('/^preg\:\/(.+)\/$/i', (string)$val, $matches)) {
                        $attrs[] = $matches[1];
                        $explanations[] = sprintf('Regex "%s" matches', $matches[1]);
                        continue;
                    }
                    $val = (string)$val;

                    $quotes = '["\']';
                    if (is_numeric($attr)) {
                        $attr = $val;
                        $val = '.+?';
                        $explanations[] = sprintf('Attribute "%s" present', $attr);
                    } elseif (!empty($val) && preg_match('/^preg\:\/(.+)\/$/i', $val, $matches)) {
                        $val = str_replace(
                            ['.*', '.+'],
                            ['.*?', '.+?'],
                            $matches[1]
                        );
                        $quotes = $val !== $matches[1] ? '["\']' : '["\']?';

                        $explanations[] = sprintf('Attribute "%s" matches "%s"', $attr, $val);
                    } else {
                        $explanations[] = sprintf('Attribute "%s" == "%s"', $attr, $val);
                        $val = preg_quote($val, '/');
                    }
                    $attrs[] = '[\s]+' . preg_quote($attr, '/') . '=' . $quotes . $val . $quotes;
                    $i++;
                }
                if ($attrs) {
                    $regex[] = [
                        'explains' => $explanations,
                        'attrs' => $attrs,
                    ];
                }
                /** @psalm-suppress PossiblyFalseArgument */
                $regex[] = [
                    sprintf('End %s tag', $tag),
                    '[\s]*\/?[\s]*>[\n\r]*',
                    $i,
                ];
            }
        }
        /**
         * @var array<string, mixed> $assertion
         */
        foreach ($regex as $i => $assertion) {
            $matches = false;
            if (isset($assertion['attrs'])) {
                $string = this._assertAttributes($assertion, $string, $fullDebug, $regex);
                if ($fullDebug === true && $string === false) {
                    debug($string, true);
                    debug($regex, true);
                }
                continue;
            }

            // If 'attrs' is not present then the array is just a regular int-offset one
            /** @psalm-suppress PossiblyUndefinedArrayOffset */
            [$description, $expressions, $itemNum] = $assertion;
            $expression = '';
            foreach ((array)$expressions as $expression) {
                $expression = sprintf('/^%s/s', $expression);
                if (preg_match($expression, $string, $match)) {
                    $matches = true;
                    $string = substr($string, strlen($match[0]));
                    break;
                }
            }
            if (!$matches) {
                if ($fullDebug === true) {
                    debug($string);
                    debug($regex);
                }
                this.assertMatchesRegularExpression(
                    $expression,
                    $string,
                    sprintf('Item #%d / regex #%d failed: %s', $itemNum, $i, $description)
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
    protected auto _assertAttributes(array $assertions, string $string, bool $fullDebug = false, $regex = '') {
        $asserts = $assertions['attrs'];
        $explains = $assertions['explains'];
        do {
            $matches = false;
            $j = null;
            foreach ($asserts as $j => $assert) {
                if (preg_match(sprintf('/^%s/s', $assert), $string, $match)) {
                    $matches = true;
                    $string = substr($string, strlen($match[0]));
                    array_splice($asserts, $j, 1);
                    array_splice($explains, $j, 1);
                    break;
                }
            }
            if ($matches === false) {
                if ($fullDebug === true) {
                    debug($string);
                    debug($regex);
                }
                this.assertTrue(false, 'Attribute did not match. Was expecting ' . $explains[$j]);
            }
            $len = count($asserts);
        } while ($len > 0);

        return $string;
    }

    /**
     * Normalize a path for comparison.
     *
     * @param string myPath Path separated by "/" slash.
     * @return string Normalized path separated by DIRECTORY_SEPARATOR.
     */
    protected string _normalizePath(string myPath) {
        return str_replace('/', DIRECTORY_SEPARATOR, myPath);
    }

// phpcs:disable

    /**
     * Compatibility function to test if a value is between an acceptable range.
     *
     * @param float $expected
     * @param float myResult
     * @param float $margin the rage of acceptation
     * @param string myMessage the text to display if the assertion is not correct
     * @return void
     */
    protected static function assertWithinRange($expected, myResult, $margin, myMessage = '') {
        $upper = myResult + $margin;
        $lower = myResult - $margin;
        static::assertTrue(($expected <= $upper) && ($expected >= $lower), myMessage);
    }

    /**
     * Compatibility function to test if a value is not between an acceptable range.
     *
     * @param float $expected
     * @param float myResult
     * @param float $margin the rage of acceptation
     * @param string myMessage the text to display if the assertion is not correct
     * @return void
     */
    protected static function assertNotWithinRange($expected, myResult, $margin, myMessage = '') {
        $upper = myResult + $margin;
        $lower = myResult - $margin;
        static::assertTrue(($expected > $upper) || ($expected < $lower), myMessage);
    }

    /**
     * Compatibility function to test paths.
     *
     * @param string $expected
     * @param string myResult
     * @param string myMessage the text to display if the assertion is not correct
     * @return void
     */
    protected static function assertPathEquals($expected, myResult, myMessage = '') {
        $expected = str_replace(DIRECTORY_SEPARATOR, '/', $expected);
        myResult = str_replace(DIRECTORY_SEPARATOR, '/', myResult);
        static::assertEquals($expected, myResult, myMessage);
    }

    /**
     * Compatibility function for skipping.
     *
     * @param bool $condition Condition to trigger skipping
     * @param string myMessage Message for skip
     * @return bool
     */
    protected auto skipUnless($condition, myMessage = '') {
        if (!$condition) {
            this.markTestSkipped(myMessage);
        }

        return $condition;
    }

// phpcs:enable

    /**
     * Mock a model, maintain fixtures and table association
     *
     * @param string myAlias The model to get a mock for.
     * @param array<string> $methods The list of methods to mock
     * @param array<string, mixed> myOptions The config data for the mock's constructor.
     * @throws \Cake\ORM\Exception\MissingTableClassException
     * @return \Cake\ORM\Table|\PHPUnit\Framework\MockObject\MockObject
     */
    auto getMockForModel(string myAlias, array $methods = [], array myOptions = []) {
        myClassName = this._getTableClassName(myAlias, myOptions);
        myConnectionName = myClassName::defaultConnectionName();
        myConnection = ConnectionManager::get(myConnectionName);

        $locator = this.getTableLocator();

        [, $baseClass] = pluginSplit(myAlias);
        myOptions += ['alias' => $baseClass, 'connection' => myConnection];
        myOptions += $locator.getConfig(myAlias);
        $reflection = new ReflectionClass(myClassName);
        myClassMethods = array_map(function ($method) {
            return $method.name;
        }, $reflection.getMethods());

        $existingMethods = array_intersect(myClassMethods, $methods);
        $nonExistingMethods = array_diff($methods, $existingMethods);

        myBuilder = this.getMockBuilder(myClassName)
            .setConstructorArgs([myOptions]);

        if ($existingMethods || !$nonExistingMethods) {
            myBuilder.onlyMethods($existingMethods);
        }

        if ($nonExistingMethods) {
            myBuilder.addMethods($nonExistingMethods);
        }

        /** @var \Cake\ORM\Table $mock */
        $mock = myBuilder.getMock();

        if (empty(myOptions['entityClass']) && $mock.getEntityClass() === Entity::class) {
            $parts = explode('\\', myClassName);
            $entityAlias = Inflector::classify(Inflector::underscore(substr(array_pop($parts), 0, -5)));
            $entityClass = implode('\\', array_slice($parts, 0, -1)) . '\\Entity\\' . $entityAlias;
            if (class_exists($entityClass)) {
                $mock.setEntityClass($entityClass);
            }
        }

        if (stripos($mock.getTable(), 'mock') === 0) {
            $mock.setTable(Inflector::tableize($baseClass));
        }

        $locator.set($baseClass, $mock);
        $locator.set(myAlias, $mock);

        return $mock;
    }

    /**
     * Gets the class name for the table.
     *
     * @param string myAlias The model to get a mock for.
     * @param array<string, mixed> myOptions The config data for the mock's constructor.
     * @return string
     * @throws \Cake\ORM\Exception\MissingTableClassException
     * @psalm-return class-string<\Cake\ORM\Table>
     */
    protected string _getTableClassName(string myAlias, array myOptions) {
        if (empty(myOptions['className'])) {
            myClass = Inflector::camelize(myAlias);
            /** @psalm-var class-string<\Cake\ORM\Table>|null */
            myClassName = App::className(myClass, 'Model/Table', 'Table');
            if (!myClassName) {
                throw new MissingTableClassException([myAlias]);
            }
            myOptions['className'] = myClassName;
        }

        return myOptions['className'];
    }

    /**
     * Set the app module
     *
     * @param string $appmodule The app module, defaults to "TestApp".
     * @return string|null The previous app module or null if not set.
     */
    static auto setAppmodule(string $appmodule = 'TestApp'): Nullable!string
    {
        $previous = Configure::read('App.module');
        Configure.write('App.module', $appmodule);

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
     * Use this method inside your test cases' {@link getFixtures()} method
     * to build up the fixture list.
     *
     * @param string $fixture Fixture
     * @return this
     */
    protected auto addFixture(string $fixture) {
        this.fixtures[] = $fixture;

        return this;
    }

    /**
     * Get the fixtures this test should use.
     *
     * @return array<string>
     */
    auto getFixtures(): array
    {
        return this.fixtures;
    }
}
