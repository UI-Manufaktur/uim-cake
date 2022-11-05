

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         4.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.TestSuite\Fixture;

import uim.baklava.Log\Log;
import uim.baklava.TestSuite\ConnectionHelper;
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
    auto executeBeforeFirstTest(): void
    {
        $helper = new ConnectionHelper();
        $helper.addTestAliases();

        myEnableLogging = in_array('--debug', $_SERVER['argv'] ?? [], true);
        if (myEnableLogging) {
            $helper.enableQueryLogging();
            Log::drop('queries');
            Log::setConfig('queries', [
                'className' => 'Console',
                'stream' => 'php://stderr',
                'scopes' => ['queriesLog'],
            ]);
        }
    }
}
