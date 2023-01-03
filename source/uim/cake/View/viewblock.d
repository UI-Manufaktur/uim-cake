


 *


 * @since         2.1.0
  */module uim.cake.View;

import uim.cake.core.exceptions.CakeException;

/**
 * ViewBlock : the concept of Blocks or Slots in the View layer.
 * Slots or blocks are combined with extending views and layouts to afford slots
 * of content that are present in a layout or parent view, but are defined by the child
 * view or elements used in the view.
 */
class ViewBlock
{
    /**
     * Override content
     */
    const string OVERRIDE = "override";

    /**
     * Append content
     */
    const string APPEND = "append";

    /**
     * Prepend content
     */
    const string PREPEND = "prepend";

    /**
     * Block content. An array of blocks indexed by name.
     *
     * @var array<string>
     */
    protected $_blocks = [];

    /**
     * The active blocks being captured.
     *
     * @var array<string>
     */
    protected $_active = [];

    /**
     * Should the currently captured content be discarded on ViewBlock::end()
     *
     * @see uim.cake.View\ViewBlock::end()
     */
    protected bool $_discardActiveBufferOnEnd = false;

    /**
     * Start capturing output for a "block"
     *
     * Blocks allow you to create slots or blocks of dynamic content in the layout.
     * view files can implement some or all of a layout"s slots.
     *
     * You can end capturing blocks using View::end(). Blocks can be output
     * using View::get();
     *
     * @param string aName The name of the block to capture for.
     * @param string $mode If ViewBlock::OVERRIDE existing content will be overridden by new content.
     *   If ViewBlock::APPEND content will be appended to existing content.
     *   If ViewBlock::PREPEND it will be prepended.
     * @throws uim.cake.Core\exceptions.CakeException When starting a block twice
     */
    void start(string aName, string $mode = ViewBlock::OVERRIDE): void
    {
        if (array_key_exists($name, _active)) {
            throw new CakeException(sprintf("A view block with the name "%s" is already/still open.", $name));
        }
        _active[$name] = $mode;
        ob_start();
    }

    /**
     * End a capturing block. The compliment to ViewBlock::start()
     *
     * @return void
     * @see uim.cake.View\ViewBlock::start()
     */
    function end(): void
    {
        if (_discardActiveBufferOnEnd) {
            _discardActiveBufferOnEnd = false;
            ob_end_clean();

            return;
        }

        if (!_active) {
            return;
        }

        $mode = end(_active);
        $active = key(_active);
        $content = ob_get_clean();
        if ($mode == ViewBlock::OVERRIDE) {
            _blocks[$active] = (string)$content;
        } else {
            this.concat($active, $content, $mode);
        }
        array_pop(_active);
    }

    /**
     * Concat content to an existing or new block.
     * Concating to a new block will create the block.
     *
     * Calling concat() without a value will create a new capturing
     * block that needs to be finished with View::end(). The content
     * of the new capturing context will be added to the existing block context.
     *
     * @param string aName Name of the block
     * @param mixed $value The content for the block. Value will be type cast
     *   to string.
     * @param string $mode If ViewBlock::APPEND content will be appended to existing content.
     *   If ViewBlock::PREPEND it will be prepended.
     */
    void concat(string aName, $value = null, $mode = ViewBlock::APPEND): void
    {
        if ($value == null) {
            this.start($name, $mode);

            return;
        }

        if (!isset(_blocks[$name])) {
            _blocks[$name] = "";
        }
        if ($mode == ViewBlock::PREPEND) {
            _blocks[$name] = $value . _blocks[$name];
        } else {
            _blocks[$name] .= $value;
        }
    }

    /**
     * Set the content for a block. This will overwrite any
     * existing content.
     *
     * @param string aName Name of the block
     * @param mixed $value The content for the block. Value will be type cast
     *   to string.
     */
    void set(string aName, $value): void
    {
        _blocks[$name] = (string)$value;
    }

    /**
     * Get the content for a block.
     *
     * @param string aName Name of the block
     * @param string $default Default string
     * @return string The block content or $default if the block does not exist.
     */
    function get(string aName, string $default = ""): string
    {
        return _blocks[$name] ?? $default;
    }

    /**
     * Check if a block exists
     *
     * @param string aName Name of the block
     */
    bool exists(string aName)
    {
        return isset(_blocks[$name]);
    }

    /**
     * Get the names of all the existing blocks.
     *
     * @return array<string> An array containing the blocks.
     */
    function keys(): array
    {
        return array_keys(_blocks);
    }

    /**
     * Get the name of the currently open block.
     *
     * @return string|null Either null or the name of the last open block.
     */
    function active(): ?string
    {
        end(_active);

        return key(_active);
    }

    /**
     * Get the unclosed/active blocks. Key is name, value is mode.
     *
     * @return array<string> An array of unclosed blocks.
     */
    function unclosed(): array
    {
        return _active;
    }
}
