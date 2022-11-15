

module uim.cakeell\Helper;

import uim.cake.console.Helper;
use UnexpectedValueException;

/**
 * Create a visually pleasing ASCII art table
 * from 2 dimensional array data.
 */
class TableHelper : Helper
{
    /**
     * Default config for this helper.
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [
        'headers' => true,
        'rowSeparator' => false,
        'headerStyle' => 'info',
    ];

    /**
     * Calculate the column widths
     *
     * @param array $rows The rows on which the columns width will be calculated on.
     * @return array<int>
     */
    protected auto _calculateWidths(array $rows): array
    {
        $widths = [];
        foreach ($rows as $line) {
            foreach (array_values($line) as $k => $v) {
                $columnLength = this._cellWidth((string)$v);
                if ($columnLength >= ($widths[$k] ?? 0)) {
                    $widths[$k] = $columnLength;
                }
            }
        }

        return $widths;
    }

    /**
     * Get the width of a cell exclusive of style tags.
     *
     * @param string $text The text to calculate a width for.
     * @return int The width of the textual content in visible characters.
     */
    protected int _cellWidth(string $text) {
        if ($text == "") {
            return 0;
        }

        if (strpos($text, '<') === false && strpos($text, '>') === false) {
            return mb_strwidth($text);
        }

        $styles = this._io.styles();
        $tags = implode('|', array_keys($styles));
        $text = preg_replace('#</?(?:' . $tags . ')>#', '', $text);

        return mb_strwidth($text);
    }

    /**
     * Output a row separator.
     *
     * @param array<int> $widths The widths of each column to output.
     * @return void
     */
    protected auto _rowSeparator(array $widths): void
    {
        $out = '';
        foreach ($widths as $column) {
            $out .= '+' . str_repeat('-', $column + 2);
        }
        $out .= '+';
        this._io.out($out);
    }

    /**
     * Output a row.
     *
     * @param array $row The row to output.
     * @param array<int> $widths The widths of each column to output.
     * @param array<string, mixed> myOptions Options to be passed.
     * @return void
     */
    protected auto _render(array $row, array $widths, array myOptions = []): void
    {
        if (count($row) === 0) {
            return;
        }

        $out = '';
        foreach (array_values($row) as $i => $column) {
            $column = (string)$column;
            $pad = $widths[$i] - this._cellWidth($column);
            if (!empty(myOptions['style'])) {
                $column = this._addStyle($column, myOptions['style']);
            }
            if ($column !== '' && preg_match('#(.*)<text-right>.+</text-right>(.*)#', $column, $matches)) {
                if ($matches[1] !== '' || $matches[2] !== '') {
                    throw new UnexpectedValueException('You cannot include text before or after the text-right tag.');
                }
                $column = str_replace(['<text-right>', '</text-right>'], '', $column);
                $out .= '| ' . str_repeat(' ', $pad) . $column . ' ';
            } else {
                $out .= '| ' . $column . str_repeat(' ', $pad) . ' ';
            }
        }
        $out .= '|';
        this._io.out($out);
    }

    /**
     * Output a table.
     *
     * Data will be output based on the order of the values
     * in the array. The keys will not be used to align data.
     *
     * @param array $args The data to render out.
     * @return void
     */
    function output(array $args): void
    {
        if (empty($args)) {
            return;
        }

        this._io.setStyle('text-right', ['text' => null]);

        myConfig = this.getConfig();
        $widths = this._calculateWidths($args);

        this._rowSeparator($widths);
        if (myConfig['headers'] === true) {
            this._render(array_shift($args), $widths, ['style' => myConfig['headerStyle']]);
            this._rowSeparator($widths);
        }

        if (empty($args)) {
            return;
        }

        foreach ($args as $line) {
            this._render($line, $widths);
            if (myConfig['rowSeparator'] === true) {
                this._rowSeparator($widths);
            }
        }
        if (myConfig['rowSeparator'] !== true) {
            this._rowSeparator($widths);
        }
    }

    /**
     * Add style tags
     *
     * @param string $text The text to be surrounded
     * @param string $style The style to be applied
     * @return string
     */
    protected auto _addStyle(string $text, string $style): string
    {
        return '<' . $style . '>' . $text . '</' . $style . '>';
    }
}
