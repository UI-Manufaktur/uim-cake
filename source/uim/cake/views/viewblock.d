module uim.cake.views;

@safe:
import uim.cake;

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
    protected _blocks = [];

    /**
     * The active blocks being captured.
     *
     * @var array<string>
     */
    protected _active = [];

    /**
     * Should the currently captured content be discarded on ViewBlock::end()
     *
     * @see uim.cake.View\ViewBlock::end()
     * @var bool
     */
    protected _discardActiveBufferOnEnd = false;

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
     * @throws uim.cake.Core\exceptions.CakeException When starting a block twice
     */
    void start(string myName, string myMode = ViewBlock::OVERRIDE) {
        if (array_key_exists(myName, _active)) {
            throw new CakeException(sprintf("A view block with the name "%s" is already/still open.", myName));
        }
        _active[myName] = myMode;
        ob_start();
    }

    /**
     * End a capturing block. The compliment to ViewBlock::start()
     *
     * @return void
     * @see uim.cake.View\ViewBlock::start()
     */
    void end() {
        if (_discardActiveBufferOnEnd) {
            _discardActiveBufferOnEnd = false;
            ob_end_clean();

            return;
        }

        if (!_active) {
            return;
        }

        myMode = end(_active);
        $active = key(_active);
        myContents = ob_get_clean();
        if (myMode == ViewBlock::OVERRIDE) {
            _blocks[$active] = (string)myContents;
        } else {
            this.concat($active, myContents, myMode);
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
     * @param string myName Name of the block
     * @param mixed myValue The content for the block. Value will be type cast
     *   to string.
     * @param string myMode If ViewBlock::APPEND content will be appended to existing content.
     *   If ViewBlock::PREPEND it will be prepended.
     */
    void concat(string myName, myValue = null, myMode = ViewBlock::APPEND) {
        if (myValue is null) {
            this.start(myName, myMode);

            return;
        }

        if (!isset(_blocks[myName])) {
            _blocks[myName] = "";
        }
        if (myMode == ViewBlock::PREPEND) {
            _blocks[myName] = myValue . _blocks[myName];
        } else {
            _blocks[myName] .= myValue;
        }
    }

    /**
     * Set the content for a block. This will overwrite any
     * existing content.
     *
     * @param string myName Name of the block
     * @param mixed myValue The content for the block. Value will be type cast
     *   to string.
     */
    void set(string myName, myValue) {
        _blocks[myName] = (string)myValue;
    }

    /**
     * Get the content for a block.
     *
     * @param string myName Name of the block
     * @param string default Default string
     * @return string The block content or $default if the block does not exist.
     */
    string get(string myName, string default = "") {
        return _blocks[myName] ?? $default;
    }

    /**
     * Check if a block exists
     *
     * @param string myName Name of the block
     */
    bool exists(string myName) {
        return isset(_blocks[myName]);
    }

    /**
     * Get the names of all the existing blocks.
     * @return An array containing the blocks.
     */
    string[] keys() {
        return array_keys(_blocks);
    }

    /**
     * Get the name of the currently open block.
     *
     * @return string|null Either null or the name of the last open block.
     */
    Nullable!string active() {
        end(_active);

        return key(_active);
    }

    /**
     * Get the unclosed/active blocks. Key is name, value is mode.
     *
     * @return An array of unclosed blocks.
     */
    string[] unclosed() {
        return _active;
    }
}
