<?php
/**
 * Carrega um arquivo da biblioteca num processo isolado e imprime, uma por
 * linha, tudo o que o PHP reportar durante a carga:
 *   <nivel>|<arquivo>:<linha>|<mensagem>    erros/avisos/deprecations capturaveis
 *   FATAL|<arquivo>:<linha>|<classe>: <msg> excecao/Error lancado na carga
 * Erros de compilacao (nao capturaveis) saem pelo display_errors do proprio PHP.
 *
 * Uso: php tools/load-test.php <dir da library> <arquivo .php>
 * Normalmente chamado por tools/load-test.sh.
 */
$lib  = $argv[1];
$file = $argv[2];
set_include_path($lib);
error_reporting(E_ALL);
set_error_handler(function ($no, $msg, $f, $l) {
    fwrite(STDOUT, "$no|" . str_replace($GLOBALS['lib'] . '/', '', $f) . ":$l|$msg\n");
    return true;
});
spl_autoload_register(function ($c) {
    $p = str_replace('_', '/', $c) . '.php';
    if (stream_resolve_include_path($p)) {
        require_once $p;
    }
});
try {
    require_once $file;
} catch (Throwable $e) {
    echo 'FATAL|' . str_replace($lib . '/', '', $e->getFile()) . ':' . $e->getLine() . '|'
        . get_class($e) . ': ' . $e->getMessage() . "\n";
}
