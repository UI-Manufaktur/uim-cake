

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.View;

/**
 * A view class that is used for AJAX responses.
 * Currently, only switches the default layout and sets the response type - which just maps to
 * text/html by default.
 */
class AjaxView : View
{
    /**
     * @inheritDoc
     */
    protected $layout = 'ajax';

    /**
     * @inheritDoc
     */
    function initialize(): void
    {
        super.initialize();
        this.setResponse(this.getResponse().withType('ajax'));
    }
}
