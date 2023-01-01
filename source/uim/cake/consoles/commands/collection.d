module uim.cake.console.commands.collection;

@safe:
import uim.cake;

/**
 * Collection for Commands.
 *
 * Used by Applications to specify their console commands.
 * UIM will use the mapped commands to construct and dispatch
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
    protected ICommand commands = [];

    /**
     * Constructor
     *
     * @param $commands The map of commands to add to the collection.
     */
    this(ICommand[string] someCommands) {
        foreach (myName, aCommand; someCommands) {
            this.add(myName, aCommand);
        }
    }

    /**
     * Add a command to the collection
     *
     * @param string myName The name of the command you want to map.
     * @param ICommand|uim.cake.consoles.Shell|string command The command to map.
     *   Can be a FQCN, Shell instance or ICommand instance.
     * @return this
     * @throws \InvalidArgumentException
     */
    function add(string myName, ICommand $command) {
        if (!is_subclass_of($command, Shell::class) && !is_subclass_of($command, ICommand::class)) {
            myClass = is_string($command) ? $command : get_class($command);
            throw new InvalidArgumentException(sprintf(
                "Cannot use "%s" for command "%s"~ " ~
                "It is not a subclass of Cake\Console\Shell or Cake\Command\Command.",
                myClass,
                myName
            ));
        }
        if (!preg_match("/^[^\s]+(?:(?: [^\s]+){1,2})?$/ui", myName)) {
            throw new InvalidArgumentException(
                "The command name `{myName}` is invalid. Names can only be a maximum of three words."
            );
        }

        this.commands[myName] = $command;

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
        foreach ($commands as myName: myClass) {
            this.add(myName, myClass);
        }

        return this;
    }

    /**
     * Remove a command from the collection if it exists.
     *
     * @param string myName The named shell.
     * @return this
     */
    function remove(string myName) {
        unset(this.commands[myName]);

        return this;
    }

    /**
     * Check whether the named shell exists in the collection.
     *
     * @param string myName The named shell.
     */
    bool has(string myName) {
        return isset(this.commands[myName]);
    }

    /**
     * Get the target for a command.
     *
     * @param string myName The named shell.
     * @return uim.cake.consoles.ICommand|uim.cake.consoles.Shell|string Either the command class or an instance.
     * @throws \InvalidArgumentException when unknown commands are fetched.
     * @psalm-return uim.cake.consoles.ICommand|uim.cake.consoles.Shell|class-string
     */
    auto get(string myName) {
        if (!this.has(myName)) {
            throw new InvalidArgumentException("The myName is not a known command name.");
        }

        return this.commands[myName];
    }

    /**
     * Implementation of IteratorAggregate.
     *
     * @return \Traversable
     * @psalm-return \Traversable<string, uim.cake.consoles.Shell|uim.cake.consoles.ICommand|class-string>
     */
    Traversable getIterator() {
        return new ArrayIterator(this.commands);
    }

    /**
     * Implementation of Countable.
     * Get the number of commands in the collection.
     */
    int count() {
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
     * @param string myPlugin The plugin to scan.
     * @return Discovered plugin commands.
     */
    STRINGAA discoverPlugin(string myPlugin) {
        $scanner = new CommandScanner();
        myShells = $scanner.scanPlugin(myPlugin);

        return this.resolveNames(myShells);
    }

    /**
     * Resolve names based on existing commands
     *
     * @param array $input The results of a CommandScanner operation.
     * @return A flat map of command names: class names.
     */
    protected STRINGAA resolveNames(array $input) {
        $out = [];
        foreach ($input as $info) {
            myName = $info["name"];
            $addLong = myName != $info["fullName"];

            // If the short name has been used, use the full name.
            // This allows app shells to have name preference.
            // and app shells to overwrite core shells.
            if (this.has(myName) && $addLong) {
                myName = $info["fullName"];
            }

            $out[myName] = $info["class"];
            if ($addLong) {
                $out[$info["fullName"]] = $info["class"];
            }
        }

        return $out;
    }

    /**
     * Automatically discover shell commands in UIM, the application and all plugins.
     *
     * Commands will be located using filesystem conventions. Commands are
     * discovered in the following order:
     *
     * - UIM provided commands
     * - Application commands
     *
     * Commands defined in the application will overwrite commands with
     * the same name provided by UIM.
     *
     * @return An array of command names and their classes.
     */
    STRINGAA autoDiscover() {
        $scanner = new CommandScanner();

        $core = this.resolveNames($scanner.scanCore());
        $app = this.resolveNames($scanner.scanApp());

        return $app + $core;
    }

    /**
     * Get the list of available command names.
     *
     * @return Command names
     */
    string[] keys() {
        return array_keys(this.commands);
    }
}
