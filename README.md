# mercadons/zf1

Maintained fork of **Zend Framework 1** (1.12.20) for modern PHP.

Zend Framework 1 reached end of life in September 2016. This fork keeps the
original API and behavior and only changes what is needed for the framework to
run cleanly on current PHP versions: no parse errors, no fatal errors and no
deprecation notices when the library is loaded on the supported versions.

It continues [`jdrumsmns/zf1_php7`](https://github.com/jdrumsmns/zf1_php7),
which stays frozen at 1.2.0 for projects that still depend on it.

## Supported PHP versions

| PHP | Status |
|-----|--------|
| 7.4 | supported |
| 8.0 – 8.3 | supported |
| 8.4 | supported |
| 8.5 | not yet supported |

Every push runs, on each supported version, `php -l` over the whole library
and a load test that includes every file in an isolated process. The build
fails on any fatal error, warning, notice or deprecation that is not one of the
known upstream problems listed in
[`tools/load-test-baseline.txt`](tools/load-test-baseline.txt). You can run the
same check locally with `PHP=php8.4 tools/load-test.sh`.

Runtime behavior is also validated against the components used by a
production application. Components outside that set are covered only by the
lint and load test; see [Known limitations](#known-limitations).

## Installation

```bash
composer require mercadons/zf1
```

Classes are autoloaded through Composer (PSR-0, `Zend_` prefix). Code that
still uses `require_once 'Zend/...'` keeps working, because the library path is
added to the include path.

## Migrating from `jdrumsmns/zf1_php7` or `zendframework/zendframework1`

1. Replace the old package in `composer.json`:

   ```diff
   -    "jdrumsmns/zf1_php7": "^1.0"
   -    "zendframework/zendframework1": "^1.12"
   +    "mercadons/zf1": "^2.0"
   ```

2. Run `composer update mercadons/zf1 jdrumsmns/zf1_php7 zendframework/zendframework1`.

This package declares `replace` for both old packages, so Composer never
installs two copies of `Zend_*` side by side.

Most applications need no code changes. Review these behavior changes before
upgrading (details in [CHANGELOG.md](CHANGELOG.md)):

1. **`Zend_Pdf` OpenType/TrueType fonts.** When reading the `cmap` table, the
   parser logged "skipping" for language-dependent format 0 subtables and for
   unsupported or unknown formats, but a `continue` inside a `switch` (which
   PHP treats as `break`) made it select that subtable anyway. It is now
   `continue 2`: the subtable is really skipped and the next one is tried; if
   none fits, `CANT_FIND_GOOD_CMAP` is thrown, as before. The same `continue`
   fix in `Zend_Form::addElements()`/`addSubForms()`, `Zend_Reflection_File`
   and `Zend_Feed_Entry_Atom` does not change their results.
2. **Serialization format.** `Zend_Http_UserAgent` (and its devices),
   `Zend_Stdlib_PriorityQueue`, `Zend_Stdlib_SplPriorityQueue` and
   `Zend_Paginator_SerializableLimitIterator` now implement
   `__serialize()`/`__unserialize()`. Objects serialized after the upgrade use
   the `O:` format instead of `C:`, also on PHP 7.4. Strings written by older
   versions (`C:`) are still read, but older versions of the library cannot
   read the new strings. Clear shared caches or sessions that hold these
   objects if old and new code run side by side.
3. **Error messages on PHP 8.** Exceptions from `Zend_Feed`, `Zend_Feed_Reader`,
   `Zend_Gdata`, `Zend_Pdf` (Flate filter) and `Zend_Search_Lucene` storage
   include the PHP error message again (it was empty on PHP 8, together with an
   "undefined variable" warning).
4. **`Zend_Paginator_SerializableLimitIterator` can be unserialized again.**
   With the `C:` format the inner `ArrayIterator` was still empty when
   `unserialize()` ran, and the call failed ("Seek position N is out of
   range"), already on PHP 7.4. Strings in the old format still fail.

## Scope

- Components are kept as in ZF1 1.12.20, with fixes for newer PHP versions.
- Adapters that depend on extensions removed from PHP core remain in the code
  but are not maintained: `mcrypt` (`Zend_Filter_Encrypt_Mcrypt`, the mcrypt
  fallback in `Zend_Crypt_Math`, `Zend_Service_ReCaptcha_MailHide`), `sqlite`
  (`Zend_Cache_Backend_Sqlite`), `mysql` (`Zend_Amf_Parse_Resource_MysqlResult`),
  `wddx` (`Zend_Serializer_Adapter_Wddx`) and `oci8`, now only available from
  PECL (`Zend_Db_Adapter_Oracle`).
- No new features are planned. Security fixes are welcome.

## Known limitations

Problems that exist in every PHP version, or that need a decision beyond a
compatibility fix, are left as they are:

- **`Zend_Ldap`** does not work on PHP 8: `ldap_first_attribute()` and
  `ldap_next_attribute()` are called with an argument removed in PHP 8.0, the
  connection check uses `is_resource()` (LDAP handles are objects since PHP
  8.1), `ldap_sort()` was removed in PHP 8.0 and the two-argument
  `ldap_connect()` is deprecated since PHP 8.3.
- **`Zend_Filter_Encrypt_Openssl`** keeps the RC4 cipher it always used
  implicitly, so existing data still opens. With OpenSSL 3, RC4 needs the
  `legacy` provider enabled in `openssl.cnf`; without it encryption and
  decryption throw `Zend_Filter_Exception`.
- **Session save handlers.** `Zend_Session::setSaveHandler()` and
  `Zend_Service_WindowsAzure_SessionHandler` use the multi-callback form of
  `session_set_save_handler()`, deprecated in PHP 8.4.
- **`E_USER_ERROR` on PHP 8.4.** `Zend_Text_Table::__toString()` and the
  navigation view helpers still stop the script with `E_USER_ERROR` when
  rendering fails; the deprecation notice is hidden from the output but still
  reaches custom error handlers.
- **`SOAP_FUNCTIONS_ALL`** (used by `Zend_Soap_Server`) is deprecated in PHP 8.4.
- **`htmlspecialchars()`/`htmlentities()` without flags** (`Zend_Mobile_Push`
  MPNS messages, `Zend_Service_WindowsAzure` table storage) follow the PHP 8.1
  default, which also escapes single quotes.
- **Dynamic properties.** `Zend_View`, the application bootstraps,
  `Zend_Controller_Action` and `Zend_Form_Element` allow them (see the
  changelog), and the ones found while testing were declared. Other components,
  and properties that applications add to their own subclasses of helpers,
  plugins or resources, may still trigger deprecation notices at runtime on PHP
  8.2+. The load test cannot detect these.
- **`null` passed to internal functions** (deprecated since PHP 8.1) is not
  fixed. For example, rendering a form element without a label or description
  triggers deprecation notices from `trim()` and `htmlspecialchars()` in the
  `Label`/`Description` decorators and `Zend_View::escape()`.
- **Upstream bugs present in all PHP versions:**
  - `Zend_Rest_Route::assemble()` is incompatible with its parent class (fatal
    error when the class is loaded).
  - `Zend_Service_WindowsAzure_Log_Writer_WindowsAzure` type-hints an
    interface that does not exist.
  - `Zend_Test_PHPUnit` requires PHPUnit 3.x/4.x classes.
  - `Zend_Search_Lucene_MultiSearcher::setDefaultSearchField()` and
    `getDefaultSearchField()` are static but use `$this`.
  - Serializing `Zend_EventManager_Filter_FilterIterator` loops forever.
  - Some `Zend_Feed`, `Zend_Gdata` and `Zend_EventManager` files fail when
    included directly instead of through their entry class, because of
    circular `require_once`.
- Findings from static analysis that do not change behavior between PHP 7.4
  and 8.4 (for example `func_get_args()` after a parameter changes, `ini_get()`
  of removed directives, code paths for PHP older than 5.6) are not changed.

## Contributing

Issues and pull requests are welcome. Please include the PHP version and a
minimal reproduction. Changes must keep working on every supported PHP version
and pass `tools/load-test.sh`.

## License

BSD-3-Clause, the same license as the original Zend Framework 1.
See [LICENSE](LICENSE). The original license is kept in
[`zendframework1/LICENSE.txt`](zendframework1/LICENSE.txt).

Zend Framework is a trademark of Zend Technologies USA, Inc. / Perforce
Software. This project is not affiliated with or endorsed by them.
