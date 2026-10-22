# Changelog

All notable changes to `mercadons/zf1`. The bundled framework is Zend
Framework 1.12.20 (`Zend_Version::VERSION` is unchanged).

## 2.0.0

First release as `mercadons/zf1`. Supports PHP 7.4 to 8.4: no parse or fatal
errors and no deprecation notices when the library is loaded, checked in CI on
7.4, 8.0, 8.1, 8.2, 8.3 and 8.4. Read the behavior changes below and the
"Known limitations" section of the README before upgrading.

### Behavior changes

- `Zend_Pdf` OpenType/TrueType fonts: `cmap` subtables that the parser logs as
  skipped (language-dependent format 0, unsupported or unknown formats) are now
  really skipped and the next subtable is tried. Before, they were selected.
- `Zend_Http_UserAgent` (and its devices), `Zend_Stdlib_PriorityQueue`,
  `Zend_Stdlib_SplPriorityQueue` and `Zend_Paginator_SerializableLimitIterator`
  are serialized in the `O:` format (`__serialize()`/`__unserialize()`) instead
  of `C:`, also on PHP 7.4. Old `C:` strings are still read; older versions of
  the library cannot read the new ones.
- On PHP 8, exceptions from `Zend_Feed`, `Zend_Feed_Reader`, `Zend_Gdata`,
  `Zend_Pdf` (Flate filter) and `Zend_Search_Lucene` storage include the PHP
  error message again (taken from `error_get_last()`).
- `Zend_Paginator_SerializableLimitIterator` can be unserialized again (with the
  `C:` format it always failed with "Seek position N is out of range").

### Package

- Composer package renamed to `mercadons/zf1`, requires `php >=7.4 <8.5` and
  declares `replace` for `jdrumsmns/zf1_php7` and `zendframework/zendframework1`.
- CI on GitHub Actions: `composer validate`, `php -l` over the whole library and
  a load test of every file (`tools/load-test.sh`), failing on any fatal error,
  warning or deprecation outside `tools/load-test-baseline.txt`.

### PHP 7.3+

- `continue` inside `switch` (a compile warning since PHP 7.3) changed to
  `continue 2` (`Zend_Form`, `Zend_Reflection_File`, `Zend_Feed_Entry_Atom`,
  `Zend_Pdf` OpenType parser).

### PHP 8.0

- `libxml_disable_entity_loader()` is only called on PHP < 8.0
  (`Zend_Xml_Security`, `Zend_Feed_Reader`).
- Array/string offset access with curly braces (`$a{0}`) replaced by `$a[0]`.
- Nested ternaries without parentheses (`Zend_Service_Console_Command`) get
  parentheses that keep the PHP 7.4 result; `unset($this)` removed
  (`Zend_Service_WindowsAzure_Storage_Batch`).
- `each()` replaced (`Zend_Config_Yaml`, `Zend_XmlRpc_Value`,
  `Zend_Http_UserAgent_Features_Adapter_TeraWurfl`); `create_function()`
  replaced by a closure (`Zend_Feed_Element`).
- `track_errors`/`$php_errormsg` replaced by `error_get_last()` in `Zend_Feed`,
  `Zend_Feed_Reader`, `Zend_Gdata`, the `Zend_Pdf` Flate filter and
  `Zend_Search_Lucene` storage.
- Dead `get_magic_quotes_gpc()` branch removed (`Zend_Tool_Project_Provider_DbAdapter`).
- Optional parameters declared before required ones lost their unusable default
  (`Zend_Pdf_Element_Reference`, `Zend_Service_WindowsAzure`).
- `Zend_Filter_Encrypt_Openssl`: `openssl_seal()`/`openssl_open()` receive
  `'RC4'` explicitly (the implicit default up to PHP 7.4, required since 8.0),
  so existing data still opens; `openssl_free_key()` only on PHP < 8.0.
- `imagepolygon()`/`imagefilledpolygon()` called without `num_points` on PHP 8.0+
  (`Zend_Barcode_Renderer_Image`).

### PHP 8.1

- `#[\ReturnTypeWillChange]` on 432 methods that implement internal interfaces
  (`ArrayAccess`, `Iterator`, `Countable`, `IteratorAggregate`, ...), always on
  its own line so PHP 7.4 reads it as a comment.
- `__serialize()`/`__unserialize()` added to the classes that implemented only
  `Serializable` (see behavior changes).
- `date_sunrise()`/`date_sunset()` are kept, silenced: `date_sun_info()` does not
  accept the zenith `Zend_Date` uses and would change the results.

### PHP 8.2

- `"${var}"` in strings replaced by `"{$var}"` (`Zend_Gdata`).
- `utf8_encode()`/`utf8_decode()` replaced by `mb_convert_encoding()` when
  mbstring is available (`Zend_Service_Amazon`, `Zend_Service_WindowsAzure`,
  `Zend_Console_Getopt`).
- Properties that were created dynamically are declared:
  `Zend_Feed_Writer_Feed_FeedAbstract::$_extensions`,
  `Zend_Translate_Adapter_Csv::$_file`.

### PHP 8.3

- `get_class()` without arguments replaced by `__CLASS__` (`Zend_OpenId_Extension_Sreg`).

### PHP 8.4

- Implicitly nullable parameters (`Type $x = null`) made explicit (`?Type $x = null`)
  in 278 parameters.
- `xml_set_object()` removed from the `Zend_Translate` XML adapters (handlers
  passed as `array($this, 'method')`).
- `E_STRICT` replaced by its value, 2048 (`Zend_Stdlib_CallbackHandler`,
  `Zend_Log`, `Zend_Tool_Framework_Loader_Abstract`).
- `fgetcsv()` receives the `escape` argument explicitly
  (`Zend_Auth_Adapter_Http_Resolver_File`, `Zend_Translate_Adapter_Csv`).
- `trigger_error(..., E_USER_ERROR)` in `Zend_Text_Table` and the navigation view
  helpers still stops the script; on 8.4 the deprecation is silenced.
- `SUNFUNCS_RET_TIMESTAMP` replaced by its value (`Zend_Date`).

## 1.2.1

Hotfix on top of 1.2.0 that restored PHP 7.4 compatibility:

- `Zend_Xml_Security::isPhpFpm()` no longer calls `str_starts_with()` (missing
  on PHP 7.4, fatal in `Zend_Date`/`Zend_Locale` with a locale) and uses the
  valid `version_compare()` operator `ge` instead of `gte` (`ValueError` on PHP 8).
- `Zend_Cache_Backend::setDirectives()` restores the `is_array()` guard.
