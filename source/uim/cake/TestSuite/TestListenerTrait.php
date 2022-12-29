


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         4.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.TestSuite;

use PHPUnit\Framework\AssertionFailedError;
use PHPUnit\Framework\Test;
use PHPUnit\Framework\TestSuite;
use PHPUnit\Framework\Warning;
use Throwable;

/**
 * : empty default methods for PHPUnit\Framework\TestListener.
 */
trait TestListenerTrait
{

    function startTestSuite(TestSuite $suite): void
    {
    }


    function endTestSuite(TestSuite $suite): void
    {
    }


    function startTest(Test $test): void
    {
    }


    function endTest(Test $test, float $time): void
    {
    }


    function addSkippedTest(Test $test, Throwable $t, float $time): void
    {
    }


    function addError(Test $test, Throwable $t, float $time): void
    {
    }


    function addWarning(Test $test, Warning $e, float $time): void
    {
    }


    function addFailure(Test $test, AssertionFailedError $e, float $time): void
    {
    }


    function addRiskyTest(Test $test, Throwable $t, float $time): void
    {
    }


    function addIncompleteTest(Test $test, Throwable $t, float $time): void
    {
    }
}
