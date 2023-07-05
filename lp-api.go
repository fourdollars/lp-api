package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"github.com/pelletier/go-toml/v2"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"net/url"
	"os"
	"path"
	"strconv"
	"strings"
	"time"
)

type Credential struct {
	Key    string `toml:"oauth_consumer_key"`
	Token  string `toml:"oauth_token"`
	Secret string `toml:"oauth_token_secret"`
}

func (c *Credential) RequestToken(oauth_consumer_key string) error {
	resp, err := http.PostForm("https://launchpad.net/+request-token",
		url.Values{
			"oauth_consumer_key":     {oauth_consumer_key},
			"oauth_signature_method": {"PLAINTEXT"},
			"oauth_signature":        {"&"},
		},
	)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return err
	}
	mesg := string(body)
	if *debug {
		log.Print(mesg)
	}
	m, err := url.ParseQuery(mesg)
	if err != nil {
		return err
	}
	c.Key = oauth_consumer_key
	c.Token = m["oauth_token"][0]
	c.Secret = m["oauth_token_secret"][0]
	return nil
}

func (c *Credential) AccessToken() error {
again:
	time.Sleep(time.Second)
	resp, err := http.PostForm("https://launchpad.net/+access-token",
		url.Values{
			"oauth_token":            {c.Token},
			"oauth_consumer_key":     {c.Key},
			"oauth_signature_method": {"PLAINTEXT"},
			"oauth_signature":        {"&" + c.Secret},
		},
	)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return err
	}
	mesg := string(body)
	if mesg == "Request token has not yet been reviewed. Try again later." {
		goto again
	} else if mesg == "End-user refused to authorize request token." {
		return errors.New(mesg)
	}
	if *debug {
		log.Print(mesg)
	}
	m, err := url.ParseQuery(mesg)
	if err != nil {
		return err
	}
	c.Token = m["oauth_token"][0]
	c.Secret = m["oauth_token_secret"][0]
	return nil
}

func (c *Credential) GetCredential() error {
	token := os.Getenv("LAUNCHPAD_TOKEN")
	if token != "" {
		keys := strings.SplitN(token, ":", 3)
		c.Key = keys[2]
		c.Token = keys[0]
		c.Secret = keys[1]
	} else if _, err := os.Stat(*conf); os.IsNotExist(err) {
		err = c.RequestToken(*key)
		if err != nil {
			return err
		}
		if strings.HasPrefix(*key, "System-wide: ") {
			log.Print(fmt.Sprintf("Please open https://launchpad.net/+authorize-token?oauth_token=%s&allow_permission=DESKTOP_INTEGRATION to authorize the token.", c.Token))
		} else {
			log.Print(fmt.Sprintf("Please open https://launchpad.net/+authorize-token?oauth_token=%s to authorize the token.", c.Token))
		}
		err = c.AccessToken()
		if err != nil {
			return err
		}
		fp, err := os.Create(*conf)
		if err != nil {
			return err
		}
		defer fp.Close()
		err = toml.NewEncoder(fp).Encode(&c)
		if err != nil {
			return err
		}
	} else {
		data, err := os.ReadFile(*conf)
		if err != nil {
			return err
		}
		err = toml.Unmarshal([]byte(data), &c)
		if err != nil {
			return err
		}
		if c.Secret == "" {
			return errors.New("Read " + *conf + " failed.")
		}
		if *debug {
			log.Print("Found " + c.Key + " " + c.Token)
		}
	}
	return nil
}

type LaunchpadAPI struct {
	Credential Credential
}

func (lp LaunchpadAPI) SetAuthHeader(header *http.Header) {
	var timestamp = time.Now().Unix()
	var auth = fmt.Sprintf("OAuth realm=\"https://api.launchpad.net/\", oauth_consumer_key=\"%s\", oauth_token=\"%s\", oauth_signature=\"&%s\", oauth_nonce=\"%d\", oauth_signature_method=\"PLAINTEXT\", oauth_timestamp=\"%d\", oauth_version=\"1.0\"", lp.Credential.Key, lp.Credential.Token, lp.Credential.Secret, timestamp, timestamp)
	if *debug {
		log.Print(auth)
	}
	header.Add("Authorization", auth)
}

func (lp LaunchpadAPI) QueryProcess(req *http.Request, args []string) {
	if len(args) > 0 {
		q := req.URL.Query()
		for _, arg := range args {
			fields := strings.Split(arg, "==")
			key := fields[0]
			value := strings.Join(fields[1:], "==")
			if len(key) > 0 && !strings.Contains(key, "=") {
				q.Add(key, value)
			}
		}
		req.URL.RawQuery = q.Encode()
		if *debug {
			log.Print("Query: ", req.URL.RawQuery)
		}
	}
}

func (lp LaunchpadAPI) DoProcess(req *http.Request) (string, error) {
	client := &http.Client{
		Timeout: 5 * time.Second,
	}
	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}
	payload := string(body)
	statusOK := resp.StatusCode >= 200 && resp.StatusCode < 300
	if !statusOK {
		var msg string
		if strings.HasPrefix(payload, "Expired token") {
			msg = payload + "\nPlease remove ~/.config/lp-api.toml if it exists and try it again."
		} else {
			msg = strconv.Itoa(resp.StatusCode) + " " + http.StatusText(resp.StatusCode) + "\n" + payload
		}
		return payload, errors.New(msg)
	}
	return payload, nil
}

func (lp *LaunchpadAPI) Delete(resource string) (string, error) {
	if *debug {
		log.Print("DELETE ", resource)
	}
	req, err := http.NewRequest("DELETE", resource, nil)
	if err != nil {
		return "", err
	}
	lp.SetAuthHeader(&req.Header)
	return lp.DoProcess(req)
}

func (lp *LaunchpadAPI) Get(resource string, args []string) (string, error) {
	if *debug {
		log.Print("GET ", resource, " ", args)
	}
	req, err := http.NewRequest("GET", resource, nil)
	if err != nil {
		return "", err
	}
	lp.SetAuthHeader(&req.Header)
	lp.QueryProcess(req, args)
	return lp.DoProcess(req)
}

func (lp *LaunchpadAPI) Download(fileUrl string) error {
	if *debug {
		log.Print("DOWNLOAD ", fileUrl)
	}
	_, err := url.Parse(fileUrl)
	if err != nil {
		log.Fatal(err)
	}
	filename := path.Base(fileUrl)
	client := &http.Client{}
	req, err := http.NewRequest("GET", strings.Replace(fileUrl, "https://launchpad.net/", lpAPI, 1), nil)
	if err != nil {
		return err
	}
	lp.SetAuthHeader(&req.Header)
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	length := int64(0)
	if len(resp.Header["Content-Length"]) == 1 {
		length, _ = strconv.ParseInt(resp.Header["Content-Length"][0], 10, 64)
	}
	defer resp.Body.Close()
	done := make(chan int64)
	file, err := os.Create(filename)
	if err != nil {
		log.Fatal(err)
	}
	if length != 0 {
		go func(done chan int64, filename string, length int64) {
			var stop bool = false
			var prev int64 = 0
			var begin = time.Now()
			fmt.Printf("Downloading %s ...\n", filename)
			file, err := os.Open(filename)
			if err != nil {
				log.Fatal(err)
			}
			defer file.Close()
			for {
				select {
				case <-done:
					stop = true
				default:
					fi, err := file.Stat()
					if err != nil {
						log.Fatal(err)
					}
					size := fi.Size()
					if size-prev != 0 {
						var percent float64 = float64(size) / float64(length) * 100
						var diff = strconv.FormatInt((length-size)/(size-prev)+1, 10) + "s"
						var left, _ = time.ParseDuration(diff)
						fmt.Printf("%.0f%% (%d/%d bytes) about %s left        \r", percent, size, length, left)
						prev = size
					}
				}
				if stop {
					var now = time.Now()
					var diff = now.Sub(begin).Truncate(time.Second)
					fmt.Printf("%s (%d bytes took %s) is downloaded.        \n", filename, length, diff)
					break
				}
				time.Sleep(time.Second)
			}
		}(done, filename, length)
	}
	defer file.Close()
	size, err := io.Copy(file, resp.Body)
	if length != 0 {
		done <- size
	} else {
		fmt.Printf("%s (%d bytes) is downloaded.\n", filename, size)
	}
	return err
}

func (lp *LaunchpadAPI) Patch(resource string, args []string) (string, error) {
	if *debug {
		log.Print("PATCH ", resource, " ", args)
	}
	data := make(map[string]interface{})
	if len(args) > 0 {
		for _, arg := range args {
			fields := strings.Split(arg, ":=")
			key := fields[0]
			value := strings.Join(fields[1:], ":=")
			if len(key) > 0 && !strings.Contains(key, "=") {
				if json.Valid([]byte(value)) {
					var v interface{}
					json.Unmarshal([]byte(value), &v)
					data[key] = v
				} else {
					log.Fatal("Invalid JSON input: " + value)
				}
			}
		}
	}
	payload, err := json.Marshal(data)
	if err != nil {
		log.Fatal(err)
	}
	if *debug {
		log.Print("JSON: ", string(payload))
	}
	req, err := http.NewRequest("PATCH", resource, bytes.NewBuffer(payload))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/json")
	lp.SetAuthHeader(&req.Header)
	lp.QueryProcess(req, args)
	return lp.DoProcess(req)
}

func (lp *LaunchpadAPI) Put(resource string, jsonFile string) (string, error) {
	if *debug {
		log.Print("PUT ", resource, " ", jsonFile)
	}
	payload, err := ioutil.ReadFile(jsonFile)
	if err != nil {
		log.Fatal("Error when opening file: ", err)
	}
	if !json.Valid(payload) {
		log.Fatal("Invalid JSON file: " + jsonFile)
	}
	if *debug {
		log.Print("JSON: ", string(payload))
	}
	req, err := http.NewRequest("PUT", resource, bytes.NewBuffer(payload))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/json")
	lp.SetAuthHeader(&req.Header)
	return lp.DoProcess(req)
}

func (lp *LaunchpadAPI) Post(resource string, args []string) (string, error) {
	if *debug {
		log.Print("POST ", resource, " ", args)
	}
	data := url.Values{}
	if len(args) > 0 {
		for _, arg := range args {
			fields := strings.Split(arg, "=")
			key := fields[0]
			key_last := strings.Split(key, "")[len(key)-1]
			value := strings.Join(fields[1:], "=")
			value_first := strings.Split(value, "")[0]
			if len(value) > 0 && value_first != "=" && key_last != ":" {
				data.Set(key, value)
			}
		}
	}
	if *debug {
		log.Print("Body: ", data.Encode())
	}
	req, err := http.NewRequest("POST", resource, strings.NewReader(data.Encode()))
	if err != nil {
		return "", err
	}
	lp.QueryProcess(req, args)
	lp.SetAuthHeader(&req.Header)
	return lp.DoProcess(req)
}

func (lp *LaunchpadAPI) Pipe(node string) (string, error) {
	bytes, err := io.ReadAll(os.Stdin)
	if err != nil {
		return "", err
	}
	var v map[string]interface{}
	json.Unmarshal(bytes, &v)
	if v[node] == nil {
		return "", errors.New("There is no such '" + node + "' key.")
	}
	if *debug {
		log.Print("PIPE ", v[node])
	}
	apiUrl, ok := v[node].(string)
	if !ok {
		return "", errors.New("The value of '" + node + "' key is not string.")
	}
	req, err := http.NewRequest("GET", apiUrl, nil)
	if err != nil {
		return "", err
	}
	lp.SetAuthHeader(&req.Header)
	return lp.DoProcess(req)
}

var conf = flag.String("conf", os.Getenv("HOME")+"/.config/lp-api.toml", "Specify the Launchpad API config file.")
var debug = flag.Bool("debug", false, "Show debug messages")
var help = flag.Bool("help", false, "Show help")
var key = flag.String("key", "System-wide: golang (https://github.com/fourdollars/lp-api)", "Specify the OAuth Consumer Key.")
var lpAPI = "https://api.launchpad.net/devel/"
var output = flag.String("output", "", "Specify the output file.")
var staging = flag.Bool("staging", false, "Use Launchpad staging server.")

func main() {
	flag.Parse()
	if *help {
		flag.Usage()
		os.Exit(0)
	}
	if *staging {
		lpAPI = "https://api.staging.launchpad.net/devel/"
	}
	args := flag.Args()
	if len(args) == 0 {
		fmt.Println("Usage: lp-api {get,patch,put,post,delete} resource, such as `lp-api get people/+me` or `lp-api get bugs/1`.\n\tPlease check https://api.launchpad.net/devel.html for details.")
		flag.Usage()
		os.Exit(0)
	} else if len(args) == 1 && !strings.HasPrefix(args[0], ".") {
		fmt.Println("Usage: lp-api {get,patch,put,post,delete} resource, such as `lp-api get people/+me` or `lp-api get bugs/1`.\n\tPlease check https://api.launchpad.net/devel.html for details.")
		flag.Usage()
		os.Exit(1)
	}

	lp := LaunchpadAPI{}
	c := Credential{}
	err := c.GetCredential()
	if err != nil {
		log.Fatal(err)
	}
	lp.Credential = c

	var resource string
	if len(args) == 1 {
		resource = ""
	} else if strings.HasPrefix(args[1], "https://api.launchpad.net/devel/") {
		resource = args[1]
		lpAPI = "https://api.launchpad.net/devel/"
	} else if strings.HasPrefix(args[1], "https://api.staging.launchpad.net/devel/") {
		resource = args[1]
		lpAPI = "https://api.staging.launchpad.net/devel/"
	} else {
		resource = lpAPI + args[1]
	}

	var payload string

	switch method := args[0]; {
	case method == "delete":
		payload, err = lp.Delete(resource)
	case method == "get":
		payload, err = lp.Get(resource, args[2:])
	case method == "patch":
		payload, err = lp.Patch(resource, args[2:])
	case method == "put":
		payload, err = lp.Put(resource, args[2])
	case method == "post":
		payload, err = lp.Post(resource, args[2:])
	case method == "download":
		err = lp.Download(args[1])
	case strings.HasPrefix(method, ".") && len(args) == 1:
		payload, err = lp.Pipe(args[0][1:])
	default:
		fmt.Printf("'%s' method is not supported.\n", method)
		os.Exit(1)
	}
	if err != nil {
		log.Fatal(err)
	}
	if *output != "" {
		if *debug {
			log.Print("OUTPUT: " + payload)
		}
		file, err := os.Create(*output)
		if err != nil {
			log.Fatal(err)
		}
		defer file.Close()
		_, err = file.WriteString(payload)
		if err != nil {
			log.Fatal(err)
		}
	} else {
		fmt.Println(payload)
	}
}
