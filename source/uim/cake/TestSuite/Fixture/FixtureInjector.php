module uim.cake.TestSuite\Fixture;

import uim.cake.TestSuite\TestCase;
import uim.cake.TestSuite\TestListenerTrait;
use PHPUnit\Framework\Test;
use PHPUnit\Framework\TestListener;
use PHPUnit\Framework\TestSuite;

/**
 * Test listener used to inject a fixture manager in all tests that
 * are composed inside a Test Suite
 *
 * @deprecated 4.3.0
 */
class FixtureInjector : TestListener
{
    use TestListenerTrait;

    /**
     * The instance of the fixture manager to use
     *
     * @var \Cake\TestSuite\Fixture\FixtureManager
     */
    protected $_fixtureManager;

    /**
     * Holds a reference to the container test suite
     *
     * @var \PHPUnit\Framework\TestSuite|null
     */
    protected $_first;

    /**
     * Constructor. Save internally the reference to the passed fixture manager
     *
     * @param \Cake\TestSuite\Fixture\FixtureManager $manager The fixture manager
     */
    this(FixtureManager $manager) {
        if (isset($_SERVER['argv'])) {
            $manager.setDebug(in_array('--debug', $_SERVER['argv'], true));
        }
        this._fixtureManager = $manager;
        this._fixtureManager.shutDown();
        TestCase::$fixtureManager = $manager;
    }

    /**
     * Iterates the tests inside a test suite and creates the required fixtures as
     * they were expressed inside each test case.
     *
     * @param \PHPUnit\Framework\TestSuite $suite The test suite
     * @return void
     */
    function startTestSuite(TestSuite $suite): void
    {
        if (empty(this._first)) {
            deprecationWarning(
                'You are using the listener based PHPUnit integration. ' .
                'This fixture system is deprecated, and we recommend you ' .
                'upgrade to the extension based PHPUnit integration. ' .
                'See https://book.cakephp.org/4.x/en/appendixes/fixture-upgrade.html',
                0
            );
            this._first = $suite;
        }
    }

    /**
     * Destroys the fixtures created by the fixture manager at the end of the test
     * suite run
     *
     * @param \PHPUnit\Framework\TestSuite $suite The test suite
     * @return void
     */
    function endTestSuite(TestSuite $suite): void
    {
        if (this._first === $suite) {
            this._fixtureManager.shutDown();
        }
    }

    /**
     * Adds fixtures to a test case when it starts.
     *
     * @param \PHPUnit\Framework\Test $test The test case
     * @return void
     */
    function startTest(Test $test): void
    {
        if ($test instanceof TestCase) {
            this._fixtureManager.fixturize($test);
            this._fixtureManager.load($test);
        }
    }

    /**
     * Unloads fixtures from the test case.
     *
     * @param \PHPUnit\Framework\Test $test The test case
     * @param float $time current time
     * @return void
     */
    function endTest(Test $test, float $time): void
    {
        if ($test instanceof TestCase) {
            this._fixtureManager.unload($test);
        }
    }
}
