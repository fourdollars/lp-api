package main

import (
	"errors"
	"flag"
	"fmt"
	"github.com/pelletier/go-toml/v2"
	"io/ioutil"
	"log"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"strings"
	"time"
)

type Credential struct {
	Key    string `toml:"oauth_consumer_key"`
	Token  string `toml:"oauth_token"`
	Secret string `toml:"oauth_token_secret"`
}

func request_token() (string, string) {
	resp, err := http.PostForm("https://launchpad.net/+request-token",
		url.Values{
			"oauth_consumer_key":     {"System-wide: golang (https://github.com/fourdollars/lp-api)"},
			"oauth_signature_method": {"PLAINTEXT"},
			"oauth_signature":        {"&"},
		},
	)
	if err != nil {
		panic(err)
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		panic(err)
	}
	mesg := string(body)
	if *debug {
		log.Print(mesg)
	}
	m, err := url.ParseQuery(mesg)
	if err != nil {
		panic(err)
	}
	return m["oauth_token"][0], m["oauth_token_secret"][0]
}

func access_token(oauth_token string, oauth_token_secret string) (Credential, error) {
again:
	time.Sleep(time.Second)
	resp, err := http.PostForm("https://launchpad.net/+access-token",
		url.Values{
			"oauth_token":            {oauth_token},
			"oauth_consumer_key":     {"System-wide: golang (https://github.com/fourdollars/lp-api)"},
			"oauth_signature_method": {"PLAINTEXT"},
			"oauth_signature":        {"&" + oauth_token_secret},
		},
	)
	if err != nil {
		return Credential{}, err
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return Credential{}, err
	}
	mesg := string(body)
	if mesg == "Request token has not yet been reviewed. Try again later." {
		goto again
	} else if mesg == "End-user refused to authorize request token." {
		return Credential{}, errors.New(mesg)
	}
	if *debug {
		log.Print(mesg)
	}
	m, err := url.ParseQuery(mesg)
	if err != nil {
		return Credential{}, err
	}
	return Credential{
		Key:    "System-wide: golang (https://github.com/fourdollars/lp-api)",
		Token:  m["oauth_token"][0],
		Secret: m["oauth_token_secret"][0],
	}, nil
}

func get_credential() Credential {
	var credential Credential
	conf := os.Getenv("HOME") + "/.config/lp-api.toml"
	if _, err := os.Stat(conf); os.IsNotExist(err) {
		oauth_token, oauth_token_secret := request_token()
		log.Print(fmt.Sprintf("Please open https://launchpad.net/+authorize-token?oauth_token=%s&allow_permission=DESKTOP_INTEGRATION to authorize the token.", oauth_token))
		credential, err = access_token(oauth_token, oauth_token_secret)
		if err != nil {
			panic(err)
		}
		bytes, err := toml.Marshal(&credential)
		if err != nil {
			panic(err)
		}
		fp, err := os.Create(conf)
		if err != nil {
			panic(err)
		}
		defer fp.Close()
		_, err = fp.Write(bytes)
		if err != nil {
			panic(err)
		}
		fp.Sync()
	} else {
		data, err := os.ReadFile(conf)
		if err != nil {
			panic(err)
		}
		err = toml.Unmarshal([]byte(data), &credential)
		if err != nil {
			panic(err)
		}
		if *debug {
			log.Print("Found " + credential.Key + " " + credential.Token)
		}
	}
	return credential
}

func set_auth_header(header *http.Header, credential Credential) {
	var timestamp = time.Now().Unix()
	var auth = fmt.Sprintf("OAuth realm=\"https://api.launchpad.net/\", oauth_consumer_key=\"%s\", oauth_token=\"%s\", oauth_signature=\"&%s\", oauth_nonce=\"%d\", oauth_signature_method=\"PLAINTEXT\", oauth_timestamp=\"%d\", oauth_version=\"1.0\"", credential.Key, credential.Token, credential.Secret, timestamp, timestamp)
	header.Add("Authorization", auth)
}

func lp_get(resource string, args []string) (string, error) {
	var credential = get_credential()
	if *debug {
		log.Print("GET ", resource, " ", args)
	}
	client := &http.Client{}
	req, err := http.NewRequest("GET", lpAPI+resource, nil)
	set_auth_header(&req.Header, credential)
	if len(args) > 0 {
		q := req.URL.Query()
		for _, arg := range args {
			fields := strings.Split(arg, "=")
			key := fields[0]
			value := strings.Join(fields[1:], "=")
			q.Add(key, value)
		}
		req.URL.RawQuery = q.Encode()
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
			msg = payload + "\nPlease remove ~/.config/lp-api.toml to try iy again."
		} else {
			msg = strconv.Itoa(resp.StatusCode) + " " + http.StatusText(resp.StatusCode) + "\n" + payload
		}
		return payload, errors.New(msg)
	}
	return payload, nil
}

func lp_post(resource string, args []string) (string, error) {
	var credential = get_credential()
	if *debug {
		log.Print("POST ", resource, " ", args)
	}
	data := url.Values{}
	if len(args) > 0 {
		for _, arg := range args {
			fields := strings.Split(arg, "=")
			key := fields[0]
			value := strings.Join(fields[1:], "=")
			data.Set(key, value)
		}
	}
	client := &http.Client{}
	req, err := http.NewRequest("POST", lpAPI+resource, strings.NewReader(data.Encode()))
	set_auth_header(&req.Header, credential)
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
			msg = payload + "\nPlease remove ~/.config/lp-api.toml to try iy again."
		} else {
			msg = strconv.Itoa(resp.StatusCode) + " " + http.StatusText(resp.StatusCode) + "\n" + payload
		}
		return payload, errors.New(msg)
	}
	return payload, nil
}

var debug = flag.Bool("debug", false, "Show debug messages")
var help = flag.Bool("help", false, "Show help")
var staging = flag.Bool("staging", false, "Use the staging Launchpad.")
var lpAPI = "https://api.launchpad.net/devel/"

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
		fmt.Println("Usage: lp-api {get,patch,put,post} resource, such as `lp-api get people/+me` or `lp-api get bugs/1`.\n\tPlease check https://api.launchpad.net/devel.html for details.")
		flag.Usage()
		os.Exit(0)
	} else if len(args) == 1 {
		fmt.Println("Usage: lp-api {get,patch,put,post} resource, such as `lp-api get people/+me` or `lp-api get bugs/1`.\n\tPlease check https://api.launchpad.net/devel.html for details.")
		flag.Usage()
		os.Exit(1)
	}

	switch method := args[0]; {
	case method == "get":
		payload, err := lp_get(args[1], args[2:])
		if err != nil {
			log.Fatal(err)
		}
		fmt.Println(payload)
	case method == "patch":
		fmt.Printf("%s is not implemented yet.\n", method)
	case method == "put":
		fmt.Printf("%s is not implemented yet.\n", method)
	case method == "post":
		payload, err := lp_post(args[1], args[2:])
		if err != nil {
			log.Fatal(err)
		}
		fmt.Println(payload)
	case method == "download":
		fmt.Printf("%s is not implemented yet.\n", method)
	default:
		fmt.Printf("%s is not supported.\n", method)
		os.Exit(1)
	}
}
