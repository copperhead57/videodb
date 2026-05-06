<?php
/**
 * HTTP client functions
 *
 * @todo    Encapsulate httpClient and Cache as separate classes
 *
 * @package Core
 * @author  Andreas Goetz   <cpuidle@gmx.de>
 * @author  Andreas Gohr    <a.gohr@web.de>
 * @author  Chinamann       <chinamann@users.sourceforge.net>
 * @version $Id: httpclient.php,v 1.21 2013/04/26 15:09:35 andig2 Exp $
 */

require_once 'core/cache.php';
require_once 'vendor/autoload.php';

use GuzzleHttp\Psr7 as Psr7;

/**
 * Reads a saved HTTP response from a cachefile.
 * If caching is globally disabled ($config['IMDBage'] <= 0), file is not loaded.
 *
 * @param   string $url URL of the cached response
 * @return  mixed       HTTP Response, false on errors
 */
function getHTTPcache($url)
{
    global $config;

    if (@$config['cache_pruning'])
    {
        $cache_file = cache_get_filename($url, CACHE_HTML);
        cache_prune_folder(dirname($cache_file).'/', $config['IMDBage']);
    }

    return cache_get($url, CACHE_HTML, $config['IMDBage'], true);
}

/**
 * Saves a HTTP resonse to a cachefile
 * If caching is globally disabled ($config['IMDBage'] <= 0), file is not saved.
 *
 * @param  string $url  URL of the response
 * @param  mixed  $resp HTTP Response
 */
function putHTTPcache($url, $data)
{
    global $config;

    // for debugging purposes track there the request originated
    $data['source'] = $url;

    cache_put($url, $data, CACHE_HTML, $config['IMDBage'], true);
}

/**
 * Extract source encoding from HTML code or HTTP header otherwise
 */
function get_response_encoding($response)
{
    $header = $encoding = null;

    // response array from cache
    if (is_array($response)) {
        if (isset($response['header']['Content-Type'])) {
            $header = $response['header']['Content-Type'];
        }
    }
    else {
        // Psr response
        $header = $response->getHeader('Content-Type');
    }

    if ($header) {
        $parsed = Psr7\parse_header($header);
        if (array_key_exists('charset', $parsed[0]))
        {
            $encoding = strtolower($parsed[0]['charset']);
        }
    }

    if (!$encoding)
    {
        $encoding = 'iso-8859-1';
    }

    return $encoding;
}

/**
 * HTTP Client
 *
 * Returns the raw data from the given URL, uses proxy when configured
 * and follows redirects
 *
 * @author Andreas Goetz <cpuidle@gmx.de>
 * @param  string  $url      URL to fetch
 * @param  bool    $cache    use caching? defaults to false
 * @param  string  $post     POST data, if nonempty POST is used instead of GET
 * @param  integer $timeout  Timeout in seconds defaults to 15
 * @return mixed             HTTP response
 */
function httpClient($url, $cache = false, $para = null, $reload = false)
{
    static $referer = 'https://www.imdb.com/search/';
    global $config;
    $client = new GuzzleHttp\Client();

    $requestConfig = [];
    $headers = '';  // additional HTTP headers, used for post data

    if (!empty($para) && array_key_exists('cookies', $para) && $para['cookies'])
    {
        $jar = new GuzzleHttp\Cookie\CookieJar();
        $requestConfig += ['cookies' => $jar];
    }

    $method  = 'GET';

    $post = isset($para['post']) ? $para['post'] : '';
    if ($post)
    {
        $method = 'POST';
        $requestConfig += ['headers' => ['Content-Type' => 'application/x-www-form-urlencoded']];
        $requestConfig += ['body' => $post];
    }

    // get data from cache?
    if ($cache &! $reload)
    {
        $resp = getHTTPcache($url.$post);
        if ($resp !== false)
        {
            $resp['cached'] = true;
            return $resp;
        }
    }

    // proxy setup
    if (!empty($config['proxy_host']) && !$para['no_proxy'])
    {
        $server = $config['proxy_host'];
        if (!($port = @$config['proxy_port']))
        {
            $port = 8080;
        }
        $requestConfig += ['proxy' => sprintf('tcp://%s:%d', $server, $port)];
    }

    // additional request headers
    if (!empty($para) && array_key_exists('header', $para) && $para['header'])
    {
        $requestConfig += ['headers' => $para['header']];
    }

    if (empty($requestConfig['headers']['Accept'])) $requestConfig['headers']['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8';
    if (empty($requestConfig['headers']['Accept-Language'])) $requestConfig['headers']['Accept-Language'] = ((isset($config['acclangbrowser']) && $config['acclangbrowser']) ? filter_input(INPUT_SERVER, 'HTTP_ACCEPT_LANGUAGE') : 'en-US;q=0.7,en;q=0.3');
    if (empty($requestConfig['headers']['DNT'])) $requestConfig['headers']['DNT'] = '1';
    if (empty($requestConfig['headers']['User-Agent'])) $requestConfig['headers']['User-Agent'] = filter_input(INPUT_SERVER, 'HTTP_USER_AGENT');
    if (empty($requestConfig['headers']['Referer'])) $requestConfig['headers']['Referer'] = $referer;

    #dlog(date("Y-m-d")." T".date("H-i-s")." - Guzzle: Before: url:".$url);
    $resp = $client->request($method, $url, $requestConfig);
    #dlog(date("Y-m-d")." T".date("H-i-s")." - Guzzle: After: url:".$url);

    $response['error'] = '';
    $response['url'] = $url;
    $response['success'] = false;
    $response['encoding'] = get_response_encoding($resp);
    $response['header'] = $resp->getHeaders();
    $response['data'] = (string) $resp->getBody();

    //* Commented out as to stop header already sent error
    //if ($config['debug']) echoHeaders($response['header'])."<p>";
    //if ($config['debug']) echo "data:<br>".htmlspecialchars($response['data'])."<p>";

    $status = $resp->getStatusCode();    
    // log response
    if ($config['httpclientlog'])
    {
        $log = fopen('httpClient.log', 'a');
        $logTime = date('Y-m-d H:i:s') . '.' . explode(' ', microtime())[1];
        fwrite($log, "****** {$logTime} - Guzzle: url: {$url} Status: {$status}");
        fwrite($log, headers_to_string($response['header']));
        fclose($log);
    }

    if ($config['debug'])
    {
        $logTime = date('Y-m-d H:i:s') . '.' . explode(' ', microtime())[1];
        dlog("******* {$logTime} - Guzzle: url: {$url} Status: {$status}");
    }
    
    // verify status code
    switch ($status)
    {
        case 200:
            $response['success'] = true;
            $response['source'] = "guzzle";
            break;

        case 202:
            // AWS WAF challenge → Playwright fallback
            $pw = runPlaywright($url);

            if (!$pw['ok']) {
                $response = [
                    'error'   => 'Playwright failed: ' . $pw['error'],
                    'url'     => $url,
                    'success' => false,
                    'source'  => 'playwright-error'
                ];
            } else {
                $response = [
                    'error'    => '',
                    'url'      => $url,
                    'success'  => true,
                    'encoding' => 'UTF-8',
                    'header'   => [],
                    'data'     => $pw['html'],
                    'wafChallengeDetected' => $pw['wafDetected'],
                //    'wafSolved' => $pw['wafSolved'],
                    'source'   => 'playwright'
                ];
            }
            break;

        default:
            $response = [
                'error'   => 'Server returned wrong status: ' . $status .
                             ' Reason: ' . $resp->getReasonPhrase(),
                'url'     => $url,
                'success' => false,
                'source'  => 'guzzle-error'
            ];
            break;
    }
    
    // @todo i'm not sure on the side-effects of setting the previous requested URL as referer
    //        for the next, so disabled for now. might be something to investigate...
    //$referer = $url;

    // commit successful request to cache
    if ($cache && $response['success'])
    {
        putHTTPcache($url.$post, $response);
    }

    return $response;
}


/**
 * Print all header info using echo
 * @param response    Object homepage Psr7\Response
 */
function echoHeaders($headers)
{
    foreach ($headers as $name => $values) {
        echo $name . ': ' . implode(', ', $values) . "<br>";
    }
}

function headers_to_string($headers)
{
    $result = '';
    foreach ($headers as $name => $values) {
        $result .= $name . ': ' . implode(', ', $values) . "\n";
    }

    return $result;
}

/**
 * Downloads an URL to the given local file
 *
 * @param   string  $url    URL to download
 * @param   string  $local  Full path to save to
 * @return  bool            true on succes else false
 */
function download($url, $local)
{
    $resp = httpClient($url);

    if (!$resp['success'])
    {
        return false;
    }

    return(@file_put_contents($local, $resp['data']) !== false);
}

function detectEnvironment(): string
{
    // 1. Windows
    if (stripos(PHP_OS_FAMILY, 'Windows') !== false) 
    {
        return 'windows';
    }

    // 2. macOS
    if (PHP_OS_FAMILY === 'Darwin') 
    {
        return 'mac';
    }

    // 3. Linux
    if (PHP_OS_FAMILY === 'Linux') 
    {
        // Detect NAS (Synology, QNAP, TrueNAS)
        $isNas = file_exists('/etc.defaults/VERSION')       // Synology
              || file_exists('/etc/config/uLinux.conf')    // QNAP
              || file_exists('/etc/truenas-version');      // TrueNAS SCALE

        if ($isNas) 
        {
            $arch = php_uname('m');
            if (stripos($arch, 'aarch64') !== false) return 'linux-nas-arm64';
            if (stripos($arch, 'x86_64') !== false) return 'linux-nas-intel';
            return 'linux-nas-unknown';
        }

        // Detect webserver user (PHP reports file owner, not Apache worker)
        $user = get_current_user();

        // Detect actual Apache worker user (System Apache or XAMPP)
        $apacheUser = trim(shell_exec("ps -eo user,args | awk '/apache2|httpd/ && !/grep/ && \$1!=\"root\" {print \$1; exit}'"));

        // XAMPP detection:
        // Must be installed AND running (daemon)
        if (file_exists('/opt/lampp') && $apacheUser === 'daemon') 
        {
            return 'linux-apache-lampp';
        }

        // Debian/Ubuntu/Mint system Apache
        if ($user === 'www-data' || $apacheUser === 'www-data') 
        {
            return 'linux-apache-system';
        }

        // RedHat/CentOS/Fedora
        if ($user === 'apache' || $apacheUser === 'apache') 
        {
            return 'linux-apache-redhat';
        }

        // Arch/Manjaro
        if ($user === 'http' || $apacheUser === 'http') 
        {
            return 'linux-apache-arch';
        }

        // Fallback
        return 'linux-unknown';
    }

    return 'unknown';
}

function runPlaywright(string $url): array
{
    global $config;

    $debug_playwright = 1;

    // LOCKING FOR QUEUING CALLS TO PLAYWRIGHT
    $lock = null;
    $lock = playwrightLock_acquire();
    if ($lock === false)
    {
        return ['ok'    => false,
                'error' => 'Playwright-timeout: ' . $url,
                'cmd'   => null
               ];
    }

    // ENVIRONMENT DETECTION
    $env = detectEnvironment();

    if ($config['debug'] || $debug_playwright) {
        dlog("**************");
        dlog("runPlaywright:detectedEnvironment: " . $env);
    }

    $path = './lib/playwright';
    $cmd  = null;

    switch ($env) 
    {
        // WINDOWS
        case 'windows':
            $node   = escapeshellarg("$path/win/node.exe");
            $script = escapeshellarg("$path/win/imdb-fetch-headed.mjs");

            $cmd =
                "cmd /C " .
                "set \"PLAYWRIGHT_BROWSERS_PATH=$path/win/node_modules/playwright-core/.local-browsers\" && " .
                "$node $script " . escapeshellarg($url);
            break;

        // macOS (placeholder) - linux install may work
        case 'mac':
        case 'mac-arm':
        case 'mac-intel':
            break;

        // LINUX (new architecture: wrapper + sudo → apache user)
        case 'linux-apache-system':
        case 'linux-apache-lampp':
            $playroot = "$path/linux";
            $wrapper = realpath("$playroot/imdb-fetch-headless.sh");
            $urlArg   = escapeshellarg($url);
            // Map environment → Apache user (must match sudoers)
            $runUser = get_current_user(); 

            $cmd = '/usr/bin/sudo -n -u ' . $runUser . " $wrapper $urlArg";
            break;

        // NAS
        case 'linux-nas-arm64':
        case 'linux-nas-intel':
            $script = escapeshellarg("$path/linux-nas-arm64/imdb-fetch.js");
            $cmd = "node $script " . escapeshellarg($url);
            break;

        // Unsupported
        default:
            return [
                'ok'    => false,
                'error' => 'Unsupported environment: ' . $env,
                'cmd'   => null
            ];
    }

    // EXECUTION
    if ($config['debug'] || $debug_playwright) {
        dlog("runPlaywright:cmd:" . $cmd);
    }

    // Capture stdout + stderr
    $output = shell_exec($cmd . " 2>&1");

    // DEBUG OUTPUT
    if ($config['debug'] || $debug_playwright) {
        dlog("runPlaywright:Start Playwright Output");
        $lines = explode("\n", (string)$output);
        while (count($lines) > 1 && trim(end($lines)) === '') {
            array_pop($lines);
        }
        // The last non-empty line is JSON
        $jsonLine = trim(end($lines));
        // Print all lines EXCEPT the last one (wrapper logs)
        for ($i = 0; $i < count($lines) - 1; $i++) 
        {
            dlog($lines[$i]);
        }
        // Truncate JSON if too long
        $max = 500;
        if (strlen($jsonLine) > $max) 
        {
            $jsonLine = substr($jsonLine, 0, $max) . "... [truncated]";
        }
        dlog("JSON: " . $jsonLine);
        dlog("runPlaywright:End Playwright Output");
    }

    // RELEASE LOCK
    playwrightLock_release($lock);

    // PARSE JSON
    if (!$output) {
        return [
            'ok'    => false,
            'error' => 'No output from Playwright',
            'cmd'   => $cmd
        ];
    }

    $lines = explode("\n", $output);
    // remove *only* empty lines at the end, not in the middle
    while (count($lines) > 1 && trim(end($lines)) === '') 
    {
        array_pop($lines);
    }
    $lastLine = trim(end($lines));

    $json = json_decode($lastLine, true);

    if (!is_array($json)) 
    {
        return [
            'ok'    => false,
            'error' => 'Invalid JSON from Playwright',
            'raw'   => $output,
            'cmd'   => $cmd
        ];
    }

    return $json;
}

function playwrightLock_acquire(int $maxAgeSeconds = 300,   // 5 minutes
                                int $maxWait = 120          // 2 minutes
                               ) 
{
    $lockFile = "./cache/locks/imdb_playwright_fetch.lock";

    if (!is_dir(dirname($lockFile))) 
    {
        @mkdir(dirname($lockFile), 0777, true);
    }

    $lock = fopen($lockFile, "c+");
    if (!$lock) 
    {
        return false;
    }

    // Check stale lock before acquiring
    $stat  = fstat($lock);
    $mtime = $stat['mtime'] ?? time();

    if (time() - $mtime > $maxAgeSeconds) 
    {
        // Stale → reset
        ftruncate($lock, 0);
    }

    $waited = 0;

    while (!flock($lock, LOCK_EX | LOCK_NB)) 
    {
        // Re-check stale while waiting
        clearstatcache(true, $lockFile);
        $fileMtime = filemtime($lockFile);

        if (time() - $fileMtime > $maxAgeSeconds) 
        {
            // Force acquire stale lock
            flock($lock, LOCK_EX);
            ftruncate($lock, 0);
            break;
        }

        sleep(1);
        $waited++;

        if ($waited >= $maxWait) 
        {
            fclose($lock);
            return false;
        }
    }

    // Update timestamp to show active lock
    ftruncate($lock, 0);
    fwrite($lock, (string)time());
    fflush($lock);

    return $lock;
}

function playwrightLock_release($lock)
{
    if ($lock) 
    {
        flock($lock, LOCK_UN);
        fclose($lock);
    }
}

?>
