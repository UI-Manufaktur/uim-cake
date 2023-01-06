


 *


 * @since         4.3.0
  */module uim.cake.TestSuite\Fixture;

import uim.cake.logs.Log;
import uim.cake.TestSuite\ConnectionHelper;
use PHPUnit\Runner\BeforeFirstTestHook;

/**
 * PHPUnit extension to integrate CakePHP"s data-only fixtures.
 */
class PHPUnitExtension : BeforeFirstTestHook
{
    /**
     * Initializes before any tests are run.
     */
    void executeBeforeFirstTest() {
        $helper = new ConnectionHelper();
        $helper.addTestAliases();

        $enableLogging = in_array("--debug", _SERVER["argv"] ?? [], true);
        if ($enableLogging) {
            $helper.enableQueryLogging();
            Log::drop("queries");
            Log::setConfig("queries", [
                "className": "Console",
                "stream": "php://stderr",
                "scopes": ["queriesLog"],
            ]);
        }
    }
}
