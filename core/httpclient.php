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

    $resp = $client->request($method, $url, $requestConfig);

    $response['error'] = '';
    $response['url'] = $url;
    $response['success'] = false;
    $response['encoding'] = get_response_encoding($resp);
    $response['header'] = $resp->getHeaders();
    $response['data'] = (string) $resp->getBody();

    if ($config['debug']) echoHeaders($response['header'])."<p>";
    if ($config['debug']) echo "data:<br>".htmlspecialchars($response['data'])."<p>";

    
    // log response
    if ($config['httpclientlog'])
    {
        $log = fopen('httpClient.log', 'a');
        fwrite($log, headers_to_string($response['header']));
        fclose($log);
    }

    $status = $resp->getStatusCode();

    switch ($status) 
    {
        case 200:
            // Your existing Guzzle-populated response stays untouched
            $response['success'] = true;
            $response['source']  = 'guzzle';
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
                    'docker'   => $pw['docker'],
                    'wafChallengeDetected' => $pw['wafChallengeDetected'],
                    'wafSolved' => $pw['wafSolved'],
                    'source'   => $pw['wafSolved'] ? 'playwright-waf-solved' : 'playwright'
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

    // Only cache successful responses
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

/*
 * new for playwright
*/
function detectEnvironment(): string
{
    // Windows
    if (stripos(PHP_OS_FAMILY, 'Windows') !== false) {
        // return 'synology';  // for testing synology from windows client 
        return 'windows';
    }

    // macOS
    if (PHP_OS_FAMILY === 'Darwin') {
        return 'mac';
    }

    // Linux (could be native or Synology)
    if (PHP_OS_FAMILY === 'Linux') {

        // Detect Synology by presence of /etc.defaults/VERSION
        if (file_exists('/etc.defaults/VERSION')) {
            return 'synology';
        }

        return 'linux';
    }

    return 'unknown';
}

function runPlaywright(string $url): array
{
    $env  = detectEnvironment();
    $root = realpath(__DIR__ . '/..');
    $path = $root . '/lib/playwright';

    // Generic script for all desktop OS
    $script = escapeshellarg("$path/imdb-fetch.js");

    switch ($env) 
    {
        case 'windows':
            $node = escapeshellarg("$path/win/node.exe");

            // Force CMD to avoid PowerShell issues
            $cmd =
                "cmd /C " .
                "set \"PLAYWRIGHT_BROWSERS_PATH=$path/win/node_modules/playwright-core/.local-browsers\" && " .
                "set \"NODE_PATH=$path/win/node_modules\" && " .
                "$node $script " . escapeshellarg($url);
            break;

        case 'mac':
            // macOS uses system Node
            $cmd = "node $script " . escapeshellarg($url);
            break;

        case 'linux':
            // Linux uses system Node
            $cmd = "node $script " . escapeshellarg($url);
            break;

        case 'synology':

            /*
             * --- PRODUCTION SYNLOGY CODE (LOCAL DOCKER RUNNER) ---
             * Uncomment if you want the PHP client to run Playwright directly on the NAS.
             *
             * $script = escapeshellarg("$path/synology/imdb-fetch.js");
             * $cmd = "node $script " . escapeshellarg($url);
             */

            // --- ACTIVE CODE: Use Synology HTTP API ---
            $cmd = sprintf(
                'curl -s "http://192.168.0.195/playwright-api.php?url=%s"',
                rawurlencode($url)
            );
            break;

        default:
            return [
                'ok'    => false,
                'error' => 'Unsupported environment'
            ];
    }

    // Capture stdout + stderr
    $output = shell_exec($cmd . " 2>&1");

    if (!$output) {
        return [
            'ok'    => false,
            'error' => 'No output from Playwright',
            'cmd'   => $cmd
        ];
    }

    $json = json_decode($output, true);

    if (!is_array($json)) {
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