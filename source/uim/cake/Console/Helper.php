


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.1.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Console;

import uim.cake.cores.InstanceConfigTrait;

/**
 * Base class for Helpers.
 *
 * Console Helpers allow you to package up reusable blocks
 * of Console output logic. For example creating tables,
 * progress bars or ascii art.
 */
abstract class Helper
{
    use InstanceConfigTrait;

    /**
     * Default config for this helper.
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [];

    /**
     * ConsoleIo instance.
     *
     * @var \Cake\Console\ConsoleIo
     */
    protected $_io;

    /**
     * Constructor.
     *
     * @param \Cake\Console\ConsoleIo $io The ConsoleIo instance to use.
     * @param array<string, mixed> $config The settings for this helper.
     */
    public this(ConsoleIo $io, array $config = []) {
        _io = $io;
        this.setConfig($config);
    }

    /**
     * This method should output content using `_io`.
     *
     * @param array $args The arguments for the helper.
     * @return void
     */
    abstract function output(array $args): void;
}
