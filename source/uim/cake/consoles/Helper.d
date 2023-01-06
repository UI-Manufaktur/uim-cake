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
     * @var uim.cake.consoles.ConsoleIo
     */
    protected $_io;

    /**
     * Constructor.
     *
     * @param uim.cake.consoles.ConsoleIo $io The ConsoleIo instance to use.
     * @param array<string, mixed> aConfig The settings for this helper.
     */
    this(ConsoleIo $io, Json aConfig = []) {
        _io = $io;
        this.setConfig(aConfig);
    }

    /**
     * This method should output content using `_io`.
     *
     * @param array $args The arguments for the helper.
     * @return void
     */
    abstract void output(array $args);
}
