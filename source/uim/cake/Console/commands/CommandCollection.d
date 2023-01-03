module uim.cake.Console;

use ArrayIterator;
use Countable;
use InvalidArgumentException;
use IteratorAggregate;
use Traversable;

/**
 * Collection for Commands.
 *
 * Used by Applications to specify their console commands.
 * CakePHP will use the mapped commands to construct and dispatch
 * shell commands.
 */
class CommandCollection : IteratorAggregate, Countable
{
    /**
     * Command list
     *
     * @var array<string, uim.cake.consoles.Shell|uim.cake.consoles.ICommand|string>
     * @psalm-var array<string, uim.cake.consoles.Shell|uim.cake.consoles.ICommand|class-string>
     * @psalm-suppress DeprecatedClass
     */
    protected $commands = [];

    /**
     * Constructor
     *
     * @param array<string, uim.cake.consoles.Shell|uim.cake.consoles.ICommand|string> $commands The map of commands to add to the collection.
     */
    this(array $commands = []) {
        foreach ($commands as $name: $command) {
            this.add($name, $command);
        }
    }

    /**
     * Add a command to the collection
     *
     * @param string aName The name of the command you want to map.
     * @param uim.cake.consoles.ICommand|uim.cake.consoles.Shell|string $command The command to map.
     *   Can be a FQCN, Shell instance or ICommand instance.
     * @return this
     * @throws \InvalidArgumentException
     */
    function add(string aName, $command) {
        if (!is_subclass_of($command, Shell::class) && !is_subclass_of($command, ICommand::class)) {
            $class = is_string($command) ? $command : get_class($command);
            throw new InvalidArgumentException(sprintf(
                "Cannot use "%s" for command "%s"~ " ~
                "It is not a subclass of Cake\Console\Shell or Cake\Command\Command.",
                $class,
                $name
            ));
        }
        if (!preg_match("/^[^\s]+(?:(?: [^\s]+){1,2})?$/ui", $name)) {
            throw new InvalidArgumentException(
                "The command name `{$name}` is invalid. Names can only be a maximum of three words."
            );
        }

        this.commands[$name] = $command;

        return this;
    }

    /**
     * Add multiple commands at once.
     *
     * @param array<string, uim.cake.consoles.Shell|uim.cake.consoles.ICommand|string> $commands A map of command names: command classes/instances.
     * @return this
     * @see uim.cake.consoles.CommandCollection::add()
     */
    function addMany(array $commands) {
        foreach ($commands as $name: $class) {
            this.add($name, $class);
        }

        return this;
    }

    /**
     * Remove a command from the collection if it exists.
     *
     * @param string aName The named shell.
     * @return this
     */
    function remove(string aName) {
        unset(this.commands[$name]);

        return this;
    }

    /**
     * Check whether the named shell exists in the collection.
     *
     * @param string aName The named shell.
     */
    bool has(string aName) {
        return isset(this.commands[$name]);
    }

    /**
     * Get the target for a command.
     *
     * @param string aName The named shell.
     * @return uim.cake.consoles.ICommand|uim.cake.consoles.Shell|string Either the command class or an instance.
     * @throws \InvalidArgumentException when unknown commands are fetched.
     * @psalm-return uim.cake.consoles.ICommand|uim.cake.consoles.Shell|class-string
     */
    function get(string aName) {
        if (!this.has($name)) {
            throw new InvalidArgumentException("The $name is not a known command name.");
        }

        return this.commands[$name];
    }

    /**
     * Implementation of IteratorAggregate.
     *
     * @return \Traversable
     * @psalm-return \Traversable<string, uim.cake.consoles.Shell|uim.cake.consoles.ICommand|class-string>
     */
    function getIterator(): Traversable
    {
        return new ArrayIterator(this.commands);
    }

    /**
     * Implementation of Countable.
     *
     * Get the number of commands in the collection.
     *
     */
    int count(): int
    {
        return count(this.commands);
    }

    /**
     * Auto-discover shell & commands from the named plugin.
     *
     * Discovered commands will have their names de-duplicated with
     * existing commands in the collection. If a command is already
     * defined in the collection and discovered in a plugin, only
     * the long name (`plugin.command`) will be returned.
     *
     * @param string $plugin The plugin to scan.
     * @return array<string, string> Discovered plugin commands.
     */
    function discoverPlugin(string $plugin): array
    {
        $scanner = new CommandScanner();
        $shells = $scanner.scanPlugin($plugin);

        return this.resolveNames($shells);
    }

    /**
     * Resolve names based on existing commands
     *
     * @param array $input The results of a CommandScanner operation.
     * @return array<string, string> A flat map of command names: class names.
     */
    protected function resolveNames(array $input): array
    {
        $out = [];
        foreach ($input as $info) {
            $name = $info["name"];
            $addLong = $name != $info["fullName"];

            // If the short name has been used, use the full name.
            // This allows app shells to have name preference.
            // and app shells to overwrite core shells.
            if (this.has($name) && $addLong) {
                $name = $info["fullName"];
            }

            $out[$name] = $info["class"];
            if ($addLong) {
                $out[$info["fullName"]] = $info["class"];
            }
        }

        return $out;
    }

    /**
     * Automatically discover shell commands in CakePHP, the application and all plugins.
     *
     * Commands will be located using filesystem conventions. Commands are
     * discovered in the following order:
     *
     * - CakePHP provided commands
     * - Application commands
     *
     * Commands defined in the application will overwrite commands with
     * the same name provided by CakePHP.
     *
     * @return array<string, string> An array of command names and their classes.
     */
    function autoDiscover(): array
    {
        $scanner = new CommandScanner();

        $core = this.resolveNames($scanner.scanCore());
        $app = this.resolveNames($scanner.scanApp());

        return $app + $core;
    }

    /**
     * Get the list of available command names.
     *
     * @return array<string> Command names
     */
    string[] keys(): array
    {
        return array_keys(this.commands);
    }
}
