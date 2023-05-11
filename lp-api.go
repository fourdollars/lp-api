package main

import (
	"errors"
	"fmt"
	"github.com/pelletier/go-toml/v2"
	"io/ioutil"
	"log"
	"net/http"
	"net/url"
	"os"
	"time"
)

type Config struct {
	Key    string `toml:"oauth_consumer_key"`
	Token  string `toml:"oauth_token"`
	Secret string `toml:"oauth_token_secret"`
}

func request_token() (string, string) {
	resp, err := http.PostForm("https://launchpad.net/+request-token",
		url.Values{
			"oauth_consumer_key":     {"System-wide: golang (lp-api)"},
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
	log.Print(mesg)
	m, err := url.ParseQuery(mesg)
	if err != nil {
		panic(err)
	}
	return m["oauth_token"][0], m["oauth_token_secret"][0]
}

func access_token(oauth_token string, oauth_token_secret string) (Config, error) {
again:
	time.Sleep(time.Second)
	resp, err := http.PostForm("https://launchpad.net/+access-token",
		url.Values{
			"oauth_token":            {oauth_token},
			"oauth_consumer_key":     {"System-wide: golang (lp-api)"},
			"oauth_signature_method": {"PLAINTEXT"},
			"oauth_signature":        {"&" + oauth_token_secret},
		},
	)
	if err != nil {
		return Config{}, err
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return Config{}, err
	}
	mesg := string(body)
	if mesg == "Request token has not yet been reviewed. Try again later." {
		goto again
	} else if mesg == "End-user refused to authorize request token." {
		return Config{}, errors.New(mesg)
	}
	log.Print(mesg)
	m, err := url.ParseQuery(mesg)
	if err != nil {
		return Config{}, err
	}
	return Config{
		Key:    "System-wide: golang (lp-api)",
		Token:  m["oauth_token"][0],
		Secret: m["oauth_token_secret"][0],
	}, nil
}

func main() {
	conf := os.Getenv("HOME") + "/.config/lp-api.toml"
	if _, err := os.Stat(conf); os.IsNotExist(err) {
		oauth_token, oauth_token_secret := request_token()
		fmt.Printf("Please open https://launchpad.net/+authorize-token?oauth_token=%s&allow_permission=DESKTOP_INTEGRATION to authorize the token.\n", oauth_token)
		config, err := access_token(oauth_token, oauth_token_secret)
		if err != nil {
			panic(err)
		}
		bytes, err := toml.Marshal(&config)
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
		var config Config
		err = toml.Unmarshal([]byte(data), &config)
		if err != nil {
			panic(err)
		}
		log.Print("Found " + config.Key + " " + config.Token)
	}
	if len(os.Args) > 1 {
		switch method := os.Args[1]; {
		case method == "get":
		case method == "download":
		case method == "patch":
		case method == "post":
		default:
			fmt.Printf("%s is not supported.\n", method)
		}
	}
}
