
module uim.cake.TestSuite;

/**
 * Compare a string to the contents of a file
 *
 * Implementing objects are expected to modify the `$_compareBasePath` property
 * before use.
 */
trait StringCompareTrait
{
    /**
     * The base path for output comparisons
     *
     * Must be initialized before use
     *
     * @var string
     */
    protected $_compareBasePath = "";

    /**
     * Update comparisons to match test changes
     *
     * Initialized with the env variable UPDATE_TEST_COMPARISON_FILES
     *
     * @var bool
     */
    protected $_updateComparisons;

    /**
     * Compare the result to the contents of the file
     *
     * @param string $path partial path to test comparison file
     * @param string $result test result as a string
     */
    void assertSameAsFile(string $path, string $result): void
    {
        if (!file_exists($path)) {
            $path = _compareBasePath . $path;
        }

        if (_updateComparisons == null) {
            _updateComparisons = env("UPDATE_TEST_COMPARISON_FILES");
        }

        if (_updateComparisons) {
            file_put_contents($path, $result);
        }

        $expected = file_get_contents($path);
        this.assertTextEquals($expected, $result, "Content does not match file " . $path);
    }
}
