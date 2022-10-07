module uim.cake.database.Type;

/**
 * : DateTimeType with support for time zones.
 */
class DateTimeTimezoneType : DateTimeType
{

    protected $_format = 'Y-m-d H:i:s.uP';


    protected $_marshalFormats = [
        'Y-m-d H:i',
        'Y-m-d H:i:s',
        'Y-m-d H:i:sP',
        'Y-m-d H:i:s.u',
        'Y-m-d H:i:s.uP',
        'Y-m-d\TH:i',
        'Y-m-d\TH:i:s',
        'Y-m-d\TH:i:sP',
        'Y-m-d\TH:i:s.u',
        'Y-m-d\TH:i:s.uP',
    ];
}
