module uim.baklava.TestSuite;

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
    protected $_compareBasePath = '';

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
     * @param string myPath partial path to test comparison file
     * @param string myResult test result as a string
     * @return void
     */
    function assertSameAsFile(string myPath, string myResult): void
    {
        if (!file_exists(myPath)) {
            myPath = this._compareBasePath . myPath;
        }

        if (this._updateComparisons === null) {
            this._updateComparisons = env('UPDATE_TEST_COMPARISON_FILES');
        }

        if (this._updateComparisons) {
            file_put_contents(myPath, myResult);
        }

        $expected = file_get_contents(myPath);
        this.assertTextEquals($expected, myResult, 'Content does not match file ' . myPath);
    }
}
