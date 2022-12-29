[![Total Downloads](https://img.shields.io/packagist/dt/cakephp/http.svg?style=flat-square)](https://packagist.org/packages/cakephp/console)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](LICENSE.txt)

# CakePHP Console Library

This library provides a framework for building command line applications from a
set of commands. It provides abstractions for defining option and argument
parsers, and dispatching commands.

# installation

You can install it from Composer. In your project:

```
composer require cakephp/console
```

# Getting Started

To start, define an entry point script and Application class which defines
bootstrap logic, and binds your commands. Lets put our entrypoint script in
`bin/tool.php`:

```php
#!/usr/bin/php -q
<?php
// Check platform requirements
require dirname(__DIR__) . "/vendor/autoload.php";

use App\Application;
import uim.cake.consoles.CommandRunner;

// Build the runner with an application and root executable name.
$runner = new CommandRunner(new Application(), "tool");
exit($runner.run($argv));
````

For our `Application` class we can start with:

```php
<?php
namespace App;

use App\Command\HelloCommand;
import uim.cake.core.IConsoleApplication;
import uim.cake.consoles.CommandCollection;

class Application : IConsoleApplication
{
    /**
     * Load all the application configuration and bootstrap logic.
     *
     * @return void
     */
    void bootstrap(): void
    {
        // Load configuration here. This is the first
        // method Cake\Console\CommandRunner will call on your application.
    }


    /**
     * Define the console commands for an application.
     *
     * @param uim.cake.consoles.CommandCollection $commands The CommandCollection to add commands into.
     * @return uim.cake.consoles.CommandCollection The updated collection.
     */
    function console(CommandCollection $commands): CommandCollection
    {
        $commands.add("hello", HelloCommand::class);

        return $commands;
    }
}
```

Next we"ll build a very simple `HelloCommand`:

```php
<?php
namespace App\Command;

import uim.cake.consoles.Arguments;
import uim.cake.consoles.BaseCommand;
import uim.cake.consoles.ConsoleIo;
import uim.cake.consoles.ConsoleOptionParser;

class HelloCommand : BaseCommand {
    protected function buildOptionParser(ConsoleOptionParser $parser): ConsoleOptionParser
    {
        $parser
            .addArgument("name", [
                "required": true,
                "help": "The name to say hello to",
            ])
            .addOption("color", [
                "choices": ["none", "green"],
                "default": "none",
                "help": "The color to use."
            ]);

        return $parser;
    }

    function execute(Arguments $args, ConsoleIo $io): ?int
    {
        $color = $args.getOption("color");
        if ($color == "none") {
            $io.out("Hello {$args.getArgument("name")}");
        } elseif ($color == "green") {
            $io.out("<success>Hello {$args.getArgument("name")}</success>");
        }

        return static::CODE_SUCCESS;
    }
}
```

Next we can run our command with `php bin/tool.php hello Syd`. To learn more
about the various features we"ve used in this example read the docs:

* [Option Parsing](https://book.cakephp.org/4/en/console-commands/option-parsers.html)
* [Input & Output](https://book.cakephp.org/4/en/console-commands/input-output.html)

