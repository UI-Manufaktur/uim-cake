module uim.cake.command.i18ns.i18n;

@safe:
import uim.cake;

// Command for interactive I18N management.
class I18nCommand : Command {
    /**
     * Execute interactive mode
     *
     * @param uim.cake.consoles.Arguments $args The command arguments.
     * @param uim.cake.consoles.ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    Nullable!int execute(Arguments someArguments, ConsoleIo aConsoleIo) {
        $io.out("<info>I18n Shell</info>");
        $io.hr();
        $io.out("[E]xtract POT file from sources");
        $io.out("[I]nitialize a language from POT file");
        $io.out("[H]elp");
        $io.out("[Q]uit");

        do {
            $choice = strtolower($io.askChoice("What would you like to do?", ["E", "I", "H", "Q"]));
            $code = null;
            switch ($choice) {
                case "e":
                    $code = this.executeCommand(I18nExtractCommand::class, [], $io);
                    break;
                case "i":
                    $code = this.executeCommand(I18nInitCommand::class, [], $io);
                    break;
                case "h":
                    $io.out(this.getOptionParser().help());
                    break;
                case "q":
                    // Do nothing
                    break;
                default:
                    $io.err(
                        "You have made an invalid selection~ " ~
                        "Please choose a command to execute by entering E, I, H, or Q."
                    );
            }
            if ($code == static::CODE_ERROR) {
                this.abort();
            }
        } while ($choice != "q");

        return static::CODE_SUCCESS;
    }

    /**
     * Gets the option parser instance and configures it.
     *
     * @param uim.cake.consoles.ConsoleOptionParser $parser The parser to update
     * @return uim.cake.consoles.ConsoleOptionParser
     */
    ConsoleOptionParser buildOptionParser(ConsoleOptionParser $parser) {
      $parser.setDescription(
          "I18n commands let you generate .pot files to power translations in your application."
      );

      return $parser;
    }
}
