module uim.cakeews;

import uim.cake.core.exceptions\CakeException;

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
     *
     * @var string
     */
    public const OVERRIDE = "override";

    /**
     * Append content
     *
     * @var string
     */
    public const APPEND = "append";

    /**
     * Prepend content
     *
     * @var string
     */
    public const PREPEND = "prepend";

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
     * @see \Cake\View\ViewBlock::end()
     * @var bool
     */
    protected $_discardActiveBufferOnEnd = false;

    /**
     * Start capturing output for a "block"
     *
     * Blocks allow you to create slots or blocks of dynamic content in the layout.
     * view files can implement some or all of a layout"s slots.
     *
     * You can end capturing blocks using View::end(). Blocks can be output
     * using View::get();
     *
     * @param string myName The name of the block to capture for.
     * @param string myMode If ViewBlock::OVERRIDE existing content will be overridden by new content.
     *   If ViewBlock::APPEND content will be appended to existing content.
     *   If ViewBlock::PREPEND it will be prepended.
     * @throws \Cake\Core\Exception\CakeException When starting a block twice
     * @return void
     */
    function start(string myName, string myMode = ViewBlock::OVERRIDE): void
    {
        if (array_key_exists(myName, this._active)) {
            throw new CakeException(sprintf("A view block with the name "%s" is already/still open.", myName));
        }
        this._active[myName] = myMode;
        ob_start();
    }

    /**
     * End a capturing block. The compliment to ViewBlock::start()
     *
     * @return void
     * @see \Cake\View\ViewBlock::start()
     */
    function end(): void
    {
        if (this._discardActiveBufferOnEnd) {
            this._discardActiveBufferOnEnd = false;
            ob_end_clean();

            return;
        }

        if (!this._active) {
            return;
        }

        myMode = end(this._active);
        $active = key(this._active);
        myContents = ob_get_clean();
        if (myMode === ViewBlock::OVERRIDE) {
            this._blocks[$active] = (string)myContents;
        } else {
            this.concat($active, myContents, myMode);
        }
        array_pop(this._active);
    }

    /**
     * Concat content to an existing or new block.
     * Concating to a new block will create the block.
     *
     * Calling concat() without a value will create a new capturing
     * block that needs to be finished with View::end(). The content
     * of the new capturing context will be added to the existing block context.
     *
     * @param string myName Name of the block
     * @param mixed myValue The content for the block. Value will be type cast
     *   to string.
     * @param string myMode If ViewBlock::APPEND content will be appended to existing content.
     *   If ViewBlock::PREPEND it will be prepended.
     * @return void
     */
    function concat(string myName, myValue = null, myMode = ViewBlock::APPEND): void
    {
        if (myValue === null) {
            this.start(myName, myMode);

            return;
        }

        if (!isset(this._blocks[myName])) {
            this._blocks[myName] = "";
        }
        if (myMode === ViewBlock::PREPEND) {
            this._blocks[myName] = myValue . this._blocks[myName];
        } else {
            this._blocks[myName] .= myValue;
        }
    }

    /**
     * Set the content for a block. This will overwrite any
     * existing content.
     *
     * @param string myName Name of the block
     * @param mixed myValue The content for the block. Value will be type cast
     *   to string.
     * @return void
     */
    auto set(string myName, myValue): void
    {
        this._blocks[myName] = (string)myValue;
    }

    /**
     * Get the content for a block.
     *
     * @param string myName Name of the block
     * @param string $default Default string
     * @return string The block content or $default if the block does not exist.
     */
    auto get(string myName, string $default = ""): string
    {
        return this._blocks[myName] ?? $default;
    }

    /**
     * Check if a block exists
     *
     * @param string myName Name of the block
     * @return bool
     */
    bool exists(string myName) {
        return isset(this._blocks[myName]);
    }

    /**
     * Get the names of all the existing blocks.
     *
     * @return array<string> An array containing the blocks.
     */
    string[] keys() {
        return array_keys(this._blocks);
    }

    /**
     * Get the name of the currently open block.
     *
     * @return string|null Either null or the name of the last open block.
     */
    function active(): Nullable!string
    {
        end(this._active);

        return key(this._active);
    }

    /**
     * Get the unclosed/active blocks. Key is name, value is mode.
     *
     * @return array<string> An array of unclosed blocks.
     */
    function unclosed(): array
    {
        return this._active;
    }
}
