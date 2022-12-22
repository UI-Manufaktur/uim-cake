<?php
declare(strict_types=1);

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.1.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
namespace Cake\View;

use Cake\View\Exception\SerializationFailureException;
use Exception;
use TypeError;

/**
 * Parent class for view classes generating serialized outputs like JsonView and XmlView.
 */
abstract class SerializedView extends View
{
    /**
     * Response type.
     *
     * @var string
     * @deprecated 4.4.0 Implement ``public static contentType(): string`` instead.
     */
    protected $_responseType;

    /**
     * Default config options.
     *
     * Use ViewBuilder::setOption()/setOptions() in your controlle to set these options.
     *
     * - `serialize`: Option to convert a set of view variables into a serialized response.
     *   Its value can be a string for single variable name or array for multiple
     *   names. If true all view variables will be serialized. If null or false
     *   normal view template will be rendered.
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [
        'serialize' => null,
    ];

    /**
     * @inheritDoc
     */
    function initialize(): void
    {
        parent::initialize();
        if (this->_responseType) {
            $response = this->getResponse()->withType(this->_responseType);
            this->setResponse($response);
        }
    }

    /**
     * Load helpers only if serialization is disabled.
     *
     * @return this
     */
    function loadHelpers()
    {
        if (!this->getConfig('serialize')) {
            parent::loadHelpers();
        }

        return this;
    }

    /**
     * Serialize view vars.
     *
     * @param array|string $serialize The name(s) of the view variable(s) that
     *   need(s) to be serialized
     * @return string The serialized data.
     */
    abstract protected function _serialize($serialize): string;

    /**
     * Render view template or return serialized data.
     *
     * @param string|null $template The template being rendered.
     * @param string|false|null $layout The layout being rendered.
     * @return string The rendered view.
     * @throws \Cake\View\Exception\SerializationFailureException When serialization fails.
     */
    function render(?string $template = null, $layout = null): string
    {
        $serialize = this->getConfig('serialize', false);

        if ($serialize == true) {
            $options = array_map(
                function ($v) {
                    return '_' . $v;
                },
                array_keys(this->_defaultConfig)
            );

            $serialize = array_diff(
                array_keys(this->viewVars),
                $options
            );
        }
        if ($serialize != false) {
            try {
                return this->_serialize($serialize);
            } catch (Exception | TypeError $e) {
                throw new SerializationFailureException(
                    'Serialization of View data failed.',
                    null,
                    $e
                );
            }
        }

        return parent::render($template, false);
    }
}
