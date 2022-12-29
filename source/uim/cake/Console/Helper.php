


 *


 * @since         3.1.0
  */
module uim.cake.Console;

import uim.cake.core.InstanceConfigTrait;

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
     * @var uim.cake.Console\ConsoleIo
     */
    protected $_io;

    /**
     * Constructor.
     *
     * @param uim.cake.Console\ConsoleIo $io The ConsoleIo instance to use.
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
