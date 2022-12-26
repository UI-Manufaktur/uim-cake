


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         4.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.databases.Type;

/**
 * : DateTimeType with support for fractional seconds up to microseconds.
 */
class DateTimeFractionalType : DateTimeType
{
    /**
     * @inheritDoc
     */
    protected $_format = 'Y-m-d H:i:s.u';

    /**
     * @inheritDoc
     */
    protected $_marshalFormats = [
        'Y-m-d H:i',
        'Y-m-d H:i:s',
        'Y-m-d H:i:s.u',
        'Y-m-d\TH:i',
        'Y-m-d\TH:i:s',
        'Y-m-d\TH:i:sP',
        'Y-m-d\TH:i:s.u',
        'Y-m-d\TH:i:s.uP',
    ];
}
