

/**
 * A class to contain test cases and run them with shared fixtures
 *
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *


 * @since         2.0.0
  */
module uim.cake.TestSuite;

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
    void addTestDirectory(string $directory = "."): void
    {
        $fs = new Filesystem();
        $files = $fs.find($directory, "/\.php$/");
        foreach ($files as $file: $fileInfo) {
            this.addTestFile($file);
        }
    }

    /**
     * Recursively adds all the files in a directory to the test suite.
     *
     * @param string $directory The directory subtree to add tests from.
     */
    void addTestDirectoryRecursive(string $directory = "."): void
    {
        $fs = new Filesystem();
        $files = $fs.findRecursive($directory, function (SplFileInfo $current) {
            $file = $current.getFilename();
            if ($file[0] == "." || !preg_match("/\.php$/", $file)) {
                return false;
            }

            return true;
        });
        foreach ($files as $file: $fileInfo) {
            this.addTestFile($file);
        }
    }
}
