


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         4.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.TestSuite\Fixture;

import uim.cake.Log\Log;
import uim.cake.TestSuite\ConnectionHelper;
use PHPUnit\Runner\BeforeFirstTestHook;

/**
 * PHPUnit extension to integrate CakePHP's data-only fixtures.
 */
class PHPUnitExtension : BeforeFirstTestHook
{
    /**
     * Initializes before any tests are run.
     *
     * @return void
     */
    function executeBeforeFirstTest(): void
    {
        $helper = new ConnectionHelper();
        $helper.addTestAliases();

        $enableLogging = in_array('--debug', $_SERVER['argv'] ?? [], true);
        if ($enableLogging) {
            $helper.enableQueryLogging();
            Log::drop('queries');
            Log::setConfig('queries', [
                'className': 'Console',
                'stream': 'php://stderr',
                'scopes': ['queriesLog'],
            ]);
        }
    }
}
