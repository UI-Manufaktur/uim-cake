/*********************************************************************************************************
  Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
  License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
  Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.consoles;

@safe:
import uim.cake;

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
    protected _defaultConfig = null;

    /**
     * ConsoleIo instance.
     *
     * @var uim.cake.consoles.ConsoleIo
     */
    protected _io;

    /**
     * Constructor.
     *
     * @param uim.cake.consoles.ConsoleIo $io The ConsoleIo instance to use.
     * @param array<string, mixed> aConfig The settings for this helper.
     */
    this(ConsoleIo $io, Json aConfig = null) {
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
