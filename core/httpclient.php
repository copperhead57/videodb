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

    
    // log response
    if ($config['httpclientlog'])
    {
        $log = fopen('httpClient.log', 'a');
        fwrite($log, headers_to_string($response['header']));
        fclose($log);
    }

    $status = $resp->getStatusCode();
    if ($config['debug'])
    {
        dlog(date("Y-m-d")." T".date("H-i-s")." - Guzzle: url:".$url." Status:".$status);
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

        // Detect desktop vs server
        $isServer = getenv('DISPLAY') === false;

        // Detect actual Apache worker user (XAMPP uses daemon)
       $apacheUser = trim(shell_exec("ps -eo user,args | awk '/httpd/ && !/grep/ && \$1!=\"root\" {print \$1; exit}'"));

        // XAMPP detection:
        // Must be installed AND running (daemon)
        if (file_exists('/opt/lampp') && $apacheUser === 'daemon') 
        {
            return 'linux-xampp';
        }

        // Debian/Ubuntu/Mint native Apache
        if ($user === 'www-data' || $apacheUser === 'www-data') 
        {
            return $isServer ? 'linux-native-server' : 'linux-native-desktop';
        }

        // RedHat/CentOS/Fedora
        if ($user === 'apache' || $apacheUser === 'apache') 
        {
            return $isServer ? 'linux-redhat-server' : 'linux-redhat-desktop';
        }

        // Arch/Manjaro
        if ($user === 'http' || $apacheUser === 'http') 
        {
            return $isServer ? 'linux-arch-server' : 'linux-arch-desktop';
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

    $env  = detectEnvironment();

    if ($config['debug'] || $debug_playwright) 
    {
        dlog("**************");
        dlog("runPlaywright:detectedEnvironment: ".$env);
    }
    $root = realpath(__DIR__ . '/..');
    $path = $root . '/lib/playwright';

    $cmd = null;

    switch ($env) {

        // * WINDOWS
        case 'windows':
            $node   = escapeshellarg("$path/win/node.exe");
            $script = escapeshellarg("$path/win/imdb-fetch-win.mjs");

            $cmd =
                "cmd /C " .
                "set \"PLAYWRIGHT_BROWSERS_PATH=$path/win/node_modules/playwright-core/.local-browsers\" && " .
                "$node $script " . escapeshellarg($url);
            break;

        // * macOS + ALL Linux variants
        case 'mac':
        case 'mac-arm':
        case 'mac-intel':
        case 'linux-native-desktop':
        case 'linux-native-server':
        case 'linux-xampp':
            $PLAYROOT   = "$path/linux-mac";
            $xvfb       = escapeshellarg("$PLAYROOT/xvfb.sh");
            $node       = "node";
            $script     = escapeshellarg("$PLAYROOT/imdb-fetch-unix.mjs");
            $urlArg     = escapeshellarg($url);

            // * get the USER or environment
            switch ($env) 
            {
                case 'mac':
                case 'mac-arm':
                case 'mac-intel':
                    $runUser = get_current_user();
                    break;

                case 'linux-native-server':
                    $runUser = 'www-data';
                    break;

                case 'linux-xampp':
                    $runUser = 'daemon';
                    break;

                case 'linux-native-desktop':
                default:
                    $runUser = get_current_user();
                    break;
            }

            $cmd = '/usr/bin/sudo -n -u ' . escapeshellarg($runUser)
                 . " $xvfb $node $script $urlArg";
            break;

        // * NAS
        case 'linux-nas-arm64':
        case 'linux-nas-intel':
            $script = escapeshellarg("$path/linux-nas-arm64/imdb-fetch.js");
            $cmd = "node $script " . escapeshellarg($url);
            break;

        default:
            return [
                'ok'    => false,
                'error' => 'Unsupported environment: '.$env
            ];
    }

    // EXECUTION
    if ($config['debug'] || $debug_playwright) {
        dlog("runPlaywright:cmd:" . $cmd);
    }

    // Capture stdout + stderr
    $output = shell_exec($cmd . " 2>&1");

    // debug trace of playwright js scripts and last line is result
    if ($config['debug'] || $debug_playwright) 
    {
        dlog("runPlaywright:Start Playwright Output");
        $lines = explode("\n", $output);
        // Remove trailing blank lines
        while (count($lines) > 1 && trim(end($lines)) === '') 
        {
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

    if (!$output) 
    {
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

?>