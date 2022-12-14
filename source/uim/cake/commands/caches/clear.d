module uim.cake.commands;

@safe:
import uim.cake;

// CacheClear command.
class CacheClearCommand : Command {

    static string defaultName() {
        return "cache clear";
    }

    /**
     * Hook method for defining this command"s option parser.
     *
     * @see https://book.UIM.org/4/en/console-commands/option-parsers.html
     * @param uim.cake.consoles.ConsoleOptionParser $parser The parser to be defined
     * @return uim.cake.consoles.ConsoleOptionParser The built parser.
     */
    ConsoleOptionParser buildOptionParser(ConsoleOptionParser $parser) {
        $parser = super.buildOptionParser($parser);
        $parser
            .setDescription("Clear all data in a single cache engine")
            .addArgument("engine", [
                "help":"The cache engine to clear." ~
                    "For example, `cake cache clear _cake_model_` will clear the model cache." ~
                    " Use `cake cache list` to list available engines.",
                "required":true,
            ]);

        return $parser;
    }

    /**
     * Implement this method with your command"s logic.
     *
     * @param uim.cake.consoles.Arguments $args The command arguments.
     * @param uim.cake.consoles.ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    Nullable!int execute(Arguments someArguments, ConsoleIo aConsoleIo) {
        myName = (string)$args.getArgument("engine");
        try {
            $io.out("Clearing {myName}");

            $engine = Cache::pool(myName);
            Cache::clear(myName);
            if ($engine instanceof ApcuEngine) {
                $io.warning("ApcuEngine detected: Cleared {myName} CLI cache successfully " ~
                    "but {myName} web cache must be cleared separately.");
            } elseif ($engine instanceof WincacheEngine) {
                $io.warning("WincacheEngine detected: Cleared {myName} CLI cache successfully " ~
                    "but {myName} web cache must be cleared separately.");
            } else {
                $io.out("<success>Cleared {myName} cache</success>");
            }
        } catch (InvalidArgumentException $e) {
            $io.error($e.getMessage());
            this.abort();
        }

        return static::CODE_SUCCESS;
    }
}
