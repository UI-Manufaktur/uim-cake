

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.4.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.errorss;

use Psr\Http\Message\IResponse;

/**
 * Interface ExceptionRendererInterface
 */
interface ExceptionRendererInterface
{
    /**
     * Renders the response for the exception.
     *
     * @return \Cake\Http\Response The response to be sent.
     */
    function render(): IResponse;
}
