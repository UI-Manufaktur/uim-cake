module uim.cake.console;

@safe:
import uim.cake;

/**
 * Base class for Helpers.
 *
 * Console Helpers allow you to package up reusable blocks
 * of Console output logic. For example creating tables,
 * progress bars or ascii art.
 */
abstract class Helper {
    use InstanceConfigTrait;

    /**
     * Default config for this helper.
     *
     * @var array<string, mixed>
     */
    protected STRINGAA _defaultConfig = [];

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
     * @param array<string, mixed> myConfig The settings for this helper.
     */
    this(ConsoleIo $io, array myConfig = []) {
        _io = $io;
        this.setConfig(myConfig);
    }

    /**
     * This method should output content using `_io`.
     *
     * @param array $args The arguments for the helper.
     */
    abstract void output(array $args);
}
