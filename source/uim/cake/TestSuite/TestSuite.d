

/**
 * A class to contain test cases and run them with shared fixtures
 *

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         2.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.TestSuite;

import uim.cake.Filesystem\Filesystem;
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
        $files = $fs.find($directory, '/\.php$/');
        foreach ($files as $file => $fileInfo) {
            this.addTestFile($file);
        }
    }

    /**
     * Recursively adds all the files in a directory to the test suite.
     *
     * @param string $directory The directory subtree to add tests from.
     */
    void addTestDirectoryRecursive(string $directory = '.') {
        $fs = new Filesystem();
        $files = $fs.findRecursive($directory, function (SplFileInfo $current) {
            $file = $current.getFilename();
            if ($file[0] === '.' || !preg_match('/\.php$/', $file)) {
                return false;
            }

            return true;
        });
        foreach ($files as $file => $fileInfo) {
            this.addTestFile($file);
        }
    }
}
