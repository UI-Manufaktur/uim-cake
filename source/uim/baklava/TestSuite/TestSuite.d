

/**
 * A class to contain test cases and run them with shared fixtures
 *

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         2.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.TestSuite;

import uim.baklava.Filesystem\Filesystem;
use PHPUnit\Framework\TestSuite as BaseTestSuite;
use SplFileInfo;

/**
 * A class to contain test cases and run them with shared fixtures
 */
class TestSuite : BaseTestSuite
{
    /**
     * Adds all the files in a directory to the test suite. Does not recursive through directories.
     *
     * @param string $directory The directory to add tests from.
     */
    void addTestDirectory(string $directory = '.') {
        $fs = new Filesystem();
        myfiles = $fs.find($directory, '/\.php$/');
        foreach (myfiles as myfile => myfileInfo) {
            this.addTestFile(myfile);
        }
    }

    /**
     * Recursively adds all the files in a directory to the test suite.
     *
     * @param string $directory The directory subtree to add tests from.
     */
    void addTestDirectoryRecursive(string $directory = '.') {
        $fs = new Filesystem();
        myfiles = $fs.findRecursive($directory, function (SplFileInfo $current) {
            myfile = $current.getFilename();
            if (myfile[0] === '.' || !preg_match('/\.php$/', myfile)) {
                return false;
            }

            return true;
        });
        foreach (myfiles as myfile => myfileInfo) {
            this.addTestFile(myfile);
        }
    }
}
