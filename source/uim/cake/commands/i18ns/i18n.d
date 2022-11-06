module uim.cakemmand;

import uim.cakensole.Arguments;
import uim.cakensole.consoleIo;
import uim.cakensole.consoleOptionParser;

/**
 * Command for interactive I18N management.
 */
class I18nCommand : Command {
    /**
     * Execute interactive mode
     *
     * @param \Cake\Console\Arguments $args The command arguments.
     * @param \Cake\Console\ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    auto execute(Arguments $args, ConsoleIo $io): Nullable!int
    {
        $io.out('<info>I18n Shell</info>');
        $io.hr();
        $io.out('[E]xtract POT file from sources');
        $io.out('[I]nitialize a language from POT file');
        $io.out('[H]elp');
        $io.out('[Q]uit');

        do {
            $choice = strtolower($io.askChoice('What would you like to do?', ['E', 'I', 'H', 'Q']));
            $code = null;
            switch ($choice) {
                case 'e':
                    $code = this.executeCommand(I18nExtractCommand::class, [], $io);
                    break;
                case 'i':
                    $code = this.executeCommand(I18nInitCommand::class, [], $io);
                    break;
                case 'h':
                    $io.out(this.getOptionParser().help());
                    break;
                case 'q':
                    // Do nothing
                    break;
                default:
                    $io.err(
                        'You have made an invalid selection. ' .
                        'Please choose a command to execute by entering E, I, H, or Q.'
                    );
            }
            if ($code === static::CODE_ERROR) {
                this.abort();
            }
        } while ($choice !== 'q');

        return static::CODE_SUCCESS;
    }

    /**
     * Gets the option parser instance and configures it.
     *
     * @param \Cake\Console\ConsoleOptionParser $parser The parser to update
     * @return \Cake\Console\ConsoleOptionParser
     */
    function buildOptionParser(ConsoleOptionParser $parser): ConsoleOptionParser
    {
        $parser.setDescription(
            'I18n commands let you generate .pot files to power translations in your application.'
        );

        return $parser;
    }
}