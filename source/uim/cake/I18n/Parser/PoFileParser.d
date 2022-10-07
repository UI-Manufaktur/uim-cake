module uim.cake.I18n\Parser;

import uim.cake.I18n\Translator;

/**
 * Parses file in PO format
 *
 * @copyright Copyright (c) 2010, Union of RAD http://union-of-rad.org (http://lithify.me/)
 * @copyright Copyright (c) 2012, Clemens Tolboom
 * @copyright Copyright (c) 2014, Fabien Potencier https://github.com/symfony/Translation/blob/master/LICENSE
 */
class PoFileParser
{
    /**
     * Parses portable object (PO) format.
     *
     * From https://www.gnu.org/software/gettext/manual/gettext.html#PO-Files
     * we should be able to parse files having:
     *
     * white-space
     * #  translator-comments
     * #. extracted-comments
     * #: reference...
     * #, flag...
     * #| msgid previous-untranslated-string
     * msgid untranslated-string
     * msgstr translated-string
     *
     * extra or different lines are:
     *
     * #| msgctxt previous-context
     * #| msgid previous-untranslated-string
     * msgctxt context
     *
     * #| msgid previous-untranslated-string-singular
     * #| msgid_plural previous-untranslated-string-plural
     * msgid untranslated-string-singular
     * msgid_plural untranslated-string-plural
     * msgstr[0] translated-string-case-0
     * ...
     * msgstr[N] translated-string-case-n
     *
     * The definition states:
     * - white-space and comments are optional.
     * - msgid "" that an empty singleline defines a header.
     *
     * This parser sacrifices some features of the reference implementation the
     * differences to that implementation are as follows.
     * - Translator and extracted comments are treated as being the same type.
     * - Message IDs are allowed to have other encodings as just US-ASCII.
     *
     * Items with an empty id are ignored.
     *
     * @param string $resource The file name to parse
     * @return array
     */
    function parse(string $resource): array
    {
        $stream = fopen($resource, 'rb');

        $defaults = [
            'ids' => [],
            'translated' => null,
        ];

        myMessages = [];
        $item = $defaults;
        $stage = [];

        while ($line = fgets($stream)) {
            $line = trim($line);

            if ($line === '') {
                // Whitespace indicated current item is done
                this._addMessage(myMessages, $item);
                $item = $defaults;
                $stage = [];
            } elseif (substr($line, 0, 7) === 'msgid "') {
                // We start a new msg so save previous
                this._addMessage(myMessages, $item);
                /** @psalm-suppress InvalidArrayOffset */
                $item['ids']['singular'] = substr($line, 7, -1);
                $stage = ['ids', 'singular'];
            } elseif (substr($line, 0, 8) === 'msgstr "') {
                $item['translated'] = substr($line, 8, -1);
                $stage = ['translated'];
            } elseif (substr($line, 0, 9) === 'msgctxt "') {
                $item['context'] = substr($line, 9, -1);
                $stage = ['context'];
            } elseif ($line[0] === '"') {
                switch (count($stage)) {
                    case 2:
                        /**
                         * @psalm-suppress PossiblyUndefinedArrayOffset
                         * @psalm-suppress InvalidArrayOffset
                         * @psalm-suppress PossiblyNullArrayAccess
                         */
                        $item[$stage[0]][$stage[1]] .= substr($line, 1, -1);
                        break;

                    case 1:
                        /**
                         * @psalm-suppress PossiblyUndefinedArrayOffset
                         * @psalm-suppress PossiblyInvalidOperand
                         * @psalm-suppress PossiblyNullOperand
                         */
                        $item[$stage[0]] .= substr($line, 1, -1);
                        break;
                }
            } elseif (substr($line, 0, 14) === 'msgid_plural "') {
                /** @psalm-suppress InvalidArrayOffset */
                $item['ids']['plural'] = substr($line, 14, -1);
                $stage = ['ids', 'plural'];
            } elseif (substr($line, 0, 7) === 'msgstr[') {
                /** @var int $size */
                $size = strpos($line, ']');
                $row = (int)substr($line, 7, 1);
                $item['translated'][$row] = substr($line, $size + 3, -1);
                $stage = ['translated', $row];
            }
        }
        // save last item
        this._addMessage(myMessages, $item);
        fclose($stream);

        return myMessages;
    }

    /**
     * Saves a translation item to the messages.
     *
     * @param array myMessages The messages array being collected from the file
     * @param array $item The current item being inspected
     * @return void
     */
    protected auto _addMessage(array &myMessages, array $item): void
    {
        if (empty($item['ids']['singular']) && empty($item['ids']['plural'])) {
            return;
        }

        $singular = stripcslashes($item['ids']['singular']);
        $context = $item['context'] ?? null;
        $translation = $item['translated'];

        if (is_array($translation)) {
            $translation = $translation[0];
        }

        $translation = stripcslashes((string)$translation);

        if ($context !== null && !isset(myMessages[$singular]['_context'][$context])) {
            myMessages[$singular]['_context'][$context] = $translation;
        } elseif (!isset(myMessages[$singular]['_context'][''])) {
            myMessages[$singular]['_context'][''] = $translation;
        }

        if (isset($item['ids']['plural'])) {
            $plurals = $item['translated'];
            // PO are by definition indexed so sort by index.
            ksort($plurals);

            // Make sure every index is filled.
            end($plurals);
            myCount = (int)key($plurals);

            // Fill missing spots with an empty string.
            $empties = array_fill(0, myCount + 1, '');
            $plurals += $empties;
            ksort($plurals);

            $plurals = array_map('stripcslashes', $plurals);
            myKey = stripcslashes($item['ids']['plural']);

            if ($context !== null) {
                myMessages[Translator::PLURAL_PREFIX . myKey]['_context'][$context] = $plurals;
            } else {
                myMessages[Translator::PLURAL_PREFIX . myKey]['_context'][''] = $plurals;
            }
        }
    }
}