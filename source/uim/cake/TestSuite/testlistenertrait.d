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

    void startTestSuite(TestSuite $suite)
    {
    }


    void endTestSuite(TestSuite $suite)
    {
    }


    void startTest(Test $test)
    {
    }


    void endTest(Test $test, float $time)
    {
    }


    void addSkippedTest(Test $test, Throwable $t, float $time)
    {
    }


    void addError(Test $test, Throwable $t, float $time)
    {
    }


    void addWarning(Test $test, Warning $e, float $time)
    {
    }


    void addFailure(Test $test, AssertionFailedError $e, float $time)
    {
    }


    void addRiskyTest(Test $test, Throwable $t, float $time)
    {
    }


    void addIncompleteTest(Test $test, Throwable $t, float $time)
    {
    }
}
